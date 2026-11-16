codeunit 90530 "KI Customer trends CodeUnit"
{

    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;
        G_SalesHeaderCreated: Boolean;
        G_SNo: Code[20];
        InsertedSalesHeader: Record "Sales Header";

    procedure CreateAndUpdateSalesOrder(_CustNumber: Code[100]; _SalesPersonCode: Code[20])
    var
        CustmerTrend: Record CustomerTrends;
        L_ExistSalesHeader: Record "Sales Header";
        L_SalesOrderCard: Page "Sales Order";
        L_SalesH: Record "Sales Header";
        L_SalesLine: Record "Sales Line";
        L_Item: Record Item;
    begin
        Clear(G_SalesHeaderCreated);
        CustmerTrend.Reset();
        CustmerTrend.SetRange("Customer No.", _CustNumber);
        CustmerTrend.SetRange("Salesperson Code", _SalesPersonCode);
        CustmerTrend.SetFilter("Qty. to be added to SO", '<>%1', 0);
        if CustmerTrend.FindSet() then begin
            if Not CheckSalesHeaderExist_But_InventoryPick_And_PostedInventoryPickNotExist(CustmerTrend) then begin
                Clear(G_SalesHeaderCreated);
                Clear(G_SNo);
            end;

            repeat
                if Not G_SalesHeaderCreated then
                    CreateSalesHeader(CustmerTrend);

                if G_SNo <> '' then begin
                    L_ExistSalesHeader.Reset();
                    L_ExistSalesHeader.SetRange("No.", G_SNo);
                    L_ExistSalesHeader.SetRange("Document Type", L_ExistSalesHeader."Document Type"::Order);
                    if L_ExistSalesHeader.FindFirst() then begin
                        // //Open Existing Order If Released++
                        // if L_ExistSalesHeader.Status = L_ExistSalesHeader.Status::Released then begin
                        //     ReleaseSalesDoc.PerformManualReopen(L_ExistSalesHeader);
                        // end;

                        //Create Lines++
                        CreateSalesLine(L_ExistSalesHeader, CustmerTrend);

                    end;
                end else begin
                    // //Open Sales Order If released++
                    // if InsertedSH.Status = InsertedSH.Status::Released then
                    //     ReleaseSalesDoc.PerformManualReopen(InsertedSH);

                    //Create Line++    
                    CreateSalesLine(InsertedSalesHeader, CustmerTrend);
                end;

            until CustmerTrend.Next() = 0;

            if G_SNo <> '' then begin
                //Check Threshold Quantity and make KNAPP Line++
                L_SalesLine.Reset();
                L_SalesLine.SetRange("Document No.", G_SNo);
                L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                if L_SalesLine.FindSet() then begin
                    repeat
                        L_Item.Reset();
                        L_Item.SetRange("No.", L_SalesLine."No.");
                        L_Item.SetRange("Knapp Item", true);
                        if L_Item.FindFirst() then begin
                            if L_Item."Knapp Threshold Quantity" <> 0 then begin
                                if L_SalesLine.Quantity < L_Item."Knapp Threshold Quantity" then begin
                                    L_SalesLine.Validate("Knapp Line", true);
                                    L_SalesLine.Modify();
                                end
                                else begin
                                    L_SalesLine.Validate("Knapp Line", false);
                                    L_SalesLine.Modify();
                                end;
                            end else begin
                                L_SalesLine.Validate("Knapp Line", true);
                                L_SalesLine.Modify();
                            end;
                        end;
                    until L_SalesLine.Next() = 0;
                end;

                //Open the Sales Order++
                If Confirm('Sales Order %1 Updated, Do you want to open?', true, G_SNo) then begin
                    Clear(L_SalesOrderCard);
                    L_SalesH.Reset();
                    L_SalesH.SetRange("Document Type", L_SalesH."Document Type"::Order);
                    L_SalesH.SetRange("No.", G_SNo);
                    if L_SalesH.FindFirst() then begin
                        L_SalesOrderCard.SetTableView(L_SalesH);
                        L_SalesOrderCard.Run();
                    end;
                end;
            end else begin
                //Check Threshold Quantity and make KNAPP Line++
                L_SalesLine.Reset();
                L_SalesLine.SetRange("Document No.", InsertedSalesHeader."No.");
                L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                if L_SalesLine.FindSet() then begin
                    repeat
                        L_Item.Reset();
                        L_Item.SetRange("No.", L_SalesLine."No.");
                        L_Item.SetRange("Knapp Item", true);
                        if L_Item.FindFirst() then begin
                            if L_Item."Knapp Threshold Quantity" <> 0 then begin
                                if L_SalesLine.Quantity < L_Item."Knapp Threshold Quantity" then begin
                                    L_SalesLine.Validate("Knapp Line", true);
                                    L_SalesLine.Modify();
                                end
                                else begin
                                    L_SalesLine.Validate("Knapp Line", false);
                                    L_SalesLine.Modify();
                                end;
                            end else begin
                                L_SalesLine.Validate("Knapp Line", true);
                                L_SalesLine.Modify();
                            end;
                        end;
                    until L_SalesLine.Next() = 0;
                end;


                //Open the Sales Order++
                If Confirm('Sales Order %1 Created, Do you want to open?', true, InsertedSalesHeader."No.") then begin
                    Clear(L_SalesOrderCard);
                    L_SalesH.Reset();
                    L_SalesH.SetRange("Document Type", L_SalesH."Document Type"::Order);
                    L_SalesH.SetRange("No.", InsertedSalesHeader."No.");
                    if L_SalesH.FindFirst() then begin
                        L_SalesOrderCard.SetTableView(L_SalesH);
                        L_SalesOrderCard.Run();
                    end;
                end;
            end;
        end;


        //Delete Customer Trends++
        //if GetLastErrorText() = '' then begin
        CustmerTrend.Reset();
        CustmerTrend.SetRange("Customer No.", _CustNumber);
        CustmerTrend.SetRange("Salesperson Code", _SalesPersonCode);
        if CustmerTrend.FindSet() then
            CustmerTrend.DeleteAll();
        //end;

    end;


    local procedure CheckSalesHeaderExist_But_InventoryPick_And_PostedInventoryPickNotExist(_CustomerTrends: Record CustomerTrends): Boolean
    var
        L_SalesHeader: Record "Sales Header";
        L_OutSTream: OutStream;
        L_WorkDescription: Text[2048];
        Crlf: Text[2];
        TypeHelper: Codeunit "Type Helper";
    begin
        Clear(L_WorkDescription);
        Clear(G_SNo);
        L_SalesHeader.Reset();
        L_SalesHeader.SetRange("Sell-to Customer No.", _CustomerTrends."Customer No.");
        L_SalesHeader.SetRange(Status, L_SalesHeader.Status::Open);
        L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
        L_SalesHeader.SetRange("Shipment Date", _CustomerTrends."Delivery Date");
        L_SalesHeader.SetRange("Location Code", _CustomerTrends."Location Code");
        L_SalesHeader.SetRange("Shipping Agent Code", _CustomerTrends."Shipping Agent Code");
        L_SalesHeader.SetRange("Shipping Agent Service Code", _CustomerTrends."Shipping Agent Service Code");
        L_SalesHeader.SetRange("Weekend Ship. Agnt. Serv. Code", _CustomerTrends."Weekend Ship. Agnt. Serv. Code");
        L_SalesHeader.SetRange("IRP Order", true);
        if L_SalesHeader.FindSet() then begin
            repeat
                //Check Inventory Pick is available+
                if not CheckInventoryPick(L_SalesHeader) then begin

                    //Check Posted Inventory Pick is Availabel+
                    if not CheckPostedInventoryPick(L_SalesHeader) then begin
                        G_SalesHeaderCreated := true;
                        G_SNo := L_SalesHeader."No.";

                        if _CustomerTrends."Work Description" <> '' then begin
                            if L_SalesHeader."Work Description".HasValue then begin
                                Crlf := TypeHelper.CRLFSeparator();
                                L_WorkDescription := L_SalesHeader.GetWorkDescription + Crlf + _CustomerTrends."Work Description";

                                Clear(L_SalesHeader."Work Description");
                                L_SalesHeader."Work Description".CreateOutStream(L_OutSTream, TextEncoding::UTF8);
                                L_OutSTream.WriteText(L_WorkDescription);
                                L_SalesHeader.Modify();
                            end else begin
                                Clear(L_SalesHeader."Work Description");
                                L_SalesHeader."Work Description".CreateOutStream(L_OutSTream, TextEncoding::UTF8);
                                L_OutSTream.WriteText(_CustomerTrends."Work Description");
                                L_SalesHeader.Modify();
                            end;
                        end;
                        exit(true);
                    end;
                end;
            until L_SalesHeader.Next() = 0;

            exit(false);
        end;
    end;




    // local procedure CheckShipmetExist(_SalesHeader: Record "Sales Header"): Boolean
    // var
    //     WarehouseShipmentLine: Record "Warehouse Shipment Line";
    // begin
    //     WarehouseShipmentLine.Reset();
    //     WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
    //     WarehouseShipmentLine.SetRange("Source No.", _SalesHeader."No.");
    //     if not WarehouseShipmentLine.IsEmpty then
    //         exit(true)
    //     else
    //         exit(false);
    // end;

    // local procedure CheckPostedShipmentExist(_SalesHeader: Record "Sales Header"): Boolean
    // var
    //     L_SalesShipmentHeader: Record "Sales Shipment Header";
    // begin
    //     L_SalesShipmentHeader.Reset();
    //     L_SalesShipmentHeader.SetRange("Order No.", _SalesHeader."No.");
    //     if not L_SalesShipmentHeader.IsEmpty then
    //         exit(true)
    //     else
    //         exit(false);
    // end;


    local procedure CheckInventoryPick(_SalesHeader: Record "Sales Header"): Boolean
    var
        L_WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        L_WarehouseActivityHeader.Reset();
        L_WarehouseActivityHeader.SetRange(Type, L_WarehouseActivityHeader.Type::"Invt. Pick");
        L_WarehouseActivityHeader.SetRange("Source Document", L_WarehouseActivityHeader."Source Document"::"Sales Order");
        L_WarehouseActivityHeader.SetRange("Source No.", _SalesHeader."No.");
        if not L_WarehouseActivityHeader.IsEmpty then
            exit(true)
        else
            exit(false);
    end;

    local procedure CheckPostedInventoryPick(_SalesHeader: Record "Sales Header"): Boolean
    var
        L_PostedInvtPickHeader: Record "Posted Invt. Pick Header";
    begin
        L_PostedInvtPickHeader.Reset();
        L_PostedInvtPickHeader.SetRange("Source Document", L_PostedInvtPickHeader."Source Document"::"Sales Order");
        L_PostedInvtPickHeader.SetRange("Source No.", _SalesHeader."No.");
        if not L_PostedInvtPickHeader.IsEmpty then
            exit(true)
        else
            exit(false);
    end;

    local procedure CreateSalesHeader(_CustmerTrend: Record CustomerTrends)
    var
        CU_NoSeries: Codeunit "No. Series";
        SalesRecSetup: Record "Sales & Receivables Setup";
        L_DocumetNo: Code[20];
        L_Customer: Record Customer;
        L_OutSTream: OutStream;
    begin
        SalesRecSetup.Get();
        InsertedSalesHeader.Reset();
        InsertedSalesHeader.Init();
        InsertedSalesHeader.Validate("Document Type", InsertedSalesHeader."Document Type"::Order);
        Clear(L_DocumetNo);
        L_DocumetNo := CU_NoSeries.GetNextNo(SalesRecSetup."Order Nos.", WORKDATE, TRUE);
        InsertedSalesHeader."No." := L_DocumetNo;
        InsertedSalesHeader.Validate("Sell-to Customer No.", _CustmerTrend."Customer No.");
        InsertedSalesHeader.Validate("Posting Date", WorkDate());
        InsertedSalesHeader.Validate("Order Date", WorkDate());
        InsertedSalesHeader.Validate("Document Date", WorkDate());
        L_Customer.Reset();
        L_Customer.SetRange("No.", _CustmerTrend."Customer No.");
        if L_Customer.FindFirst() then
            InsertedSalesHeader."Knapp Customer" := L_Customer."Knapp Customer";

        InsertedSalesHeader.Validate("IRP Order", true);
        if _CustmerTrend."Work Description" <> '' then begin
            InsertedSalesHeader."Work Description".CreateOutStream(L_OutSTream, TextEncoding::UTF8);
            L_OutSTream.WriteText(_CustmerTrend."Work Description");
        end;

        InsertedSalesHeader.Insert(true);


        //Update Shipment date and Location++
        InsertedSalesHeader.Validate("Location Code", _CustmerTrend."Location Code");
        InsertedSalesHeader.Validate("Shipment Date", _CustmerTrend."Delivery Date");
        InsertedSalesHeader.Validate("Shipping Agent Code", _CustmerTrend."Shipping Agent Code");
        InsertedSalesHeader.Validate("Shipping Agent Service Code", _CustmerTrend."Shipping Agent Service Code");
        InsertedSalesHeader.Validate("Weekend Ship. Agnt. Serv. Code", _CustmerTrend."Weekend Ship. Agnt. Serv. Code");
        InsertedSalesHeader.Modify();
        G_SalesHeaderCreated := true;
    end;

    local procedure CreateSalesLine(_SalesHeader: Record "Sales Header"; _Customertrend: Record CustomerTrends)
    var
        InsertedSL: Record "Sales Line";
        L_Zone: Record Zone;
        L_Item: Record Item;
    begin
        InsertedSL.Reset();
        InsertedSL.SetRange("Document Type", InsertedSL."Document Type"::Order);
        InsertedSL.SetRange("Document No.", _SalesHeader."No.");
        InsertedSL.SetRange("No.", _Customertrend."Item No.");
        InsertedSL.SetRange(Type, InsertedSL.Type::Item);
        InsertedSL.SetRange("Sent to Knapp", false);
        if InsertedSL.FindFirst() then begin
            InsertedSL.Validate(Quantity, InsertedSL.Quantity + _Customertrend."Qty. to be added to SO");
            InsertedSL.Modify(true);
        end else begin
            InsertedSL.Init();
            InsertedSL.VALIDATE("Document Type", InsertedSL."Document Type"::Order);
            InsertedSL.VALIDATE("Document No.", _SalesHeader."No.");
            InsertedSL.VALIDATE("Line No.", GetLastLineNo(_SalesHeader."No."));
            InsertedSL.VALIDATE(Type, InsertedSL.Type::Item);
            InsertedSL.VALIDATE("No.", _Customertrend."Item No.");
            //We are using one location setup For Purchase and Sales++
            InsertedSL.Validate("Location Code", _SalesHeader."Location Code");
            InsertedSL.VALIDATE(Quantity, _Customertrend."Qty. to be added to SO");
            L_Item.Reset();
            L_Item.SetRange("No.", _Customertrend."Item No.");
            if L_Item.FindFirst() then
                InsertedSL.Validate("Knapp Item", L_Item."Knapp Item");



            //Below are the conditions
            //1. If Customer is KNAPP, only then check validations in Sales line level
            //2. If Customer is not KNAPP, then the entire SO will be a Manual Pick. Need to still have a separate Fridge and CD Picks.
            //3. KNAPP Item – If Customer is KNAPP and Item is not KNAPP, then Manual Pick
            //4. KNAPP Route – If Customer is KNAPP and Shipping Agent Service Code is not KNAPP, then Manual Pick
            //5. If Item is KNAPP and below Threshold then send it KNAPP
            //6. If Item is KNAPP and over Threshold, then Manual Pick (SH/Unit1)
            //7. If Item is not KNAPP, then always Manual Pick (SH/Unit1)
            //9. Fridge – Always separate Pick irrespective of KNAPP or Manual Pick
            //10. CD – Always separate Pick irrespective of KNAPP or Manual Pick
            //11. If the qty is above the Threshold on item card, then system has to automatically suggest SH/Unit1 else HDH
            //13. Potentially we don’t have to assign Variants on SO, it has to auto-fill based on the Inventory Pick post

            // //Knapp Customer++
            //Knapp Customer++
            if (CheckKnaapCustomer(InsertedSL."Sell-to Customer No.") = true) AND (CheckKnaapShippingAgentService(_SalesHeader) = true) AND (CheckKnaapItem(InsertedSL."No.") = true) then
                InsertedSL.Validate("Knapp Line", true);

            // if (CheckKnaapCustomer(InsertedSL."Sell-to Customer No.") = true) AND (CheckKnaapShippingAgentService(_SalesHeader) = true) then begin
            //     if (CheckKnaapItem(InsertedSL."No.") = true) then begin
            //         InsertedSL.Validate("Knapp Line", true);
            //         //KNAPP
            //         L_Zone.Reset();
            //         L_Zone.SetRange("Knapp Zone", true);
            //         if L_Zone.FindFirst() then begin
            //             InsertedSL.Validate("Bin Code", GetBinCodeFromBincontent(InsertedSL, _SalesHeader, L_Zone));
            //             InsertedSL.Validate("Knapp Line", true);
            //         end else
            //             Error('Knaap Zone is not available in BC. Please create and try again');
            //     end;
            //     //Manual++
            //     if (CheckKnaapItem(InsertedSL."No.") = false) then begin
            //         L_Zone.Reset();
            //         L_Zone.SetRange("Knapp Zone", false);
            //         if L_Zone.FindFirst() then begin
            //             InsertedSL.Validate("Bin Code", GetBinCodeFromBincontent(InsertedSL, _SalesHeader, L_Zone));
            //         end else
            //             Error('Manual Zone is not available in BC. Please create and try again');
            //     end;
            // end else begin
            //     //Manual++
            //     L_Zone.Reset();
            //     L_Zone.SetRange("Knapp Zone", false);
            //     if L_Zone.FindFirst() then begin
            //         InsertedSL.Validate("Bin Code", GetBinCodeFromBincontent(InsertedSL, _SalesHeader, L_Zone));
            //     end else
            //         Error('Manual Zone is not available in BC. Please create and try again');
            // end;

            InsertedSL.Validate("Unit Price", _Customertrend."Unit Price");
            InsertedSL."Last Price" := _Customertrend."Last Price";
            //InsertedSL."Shipper Qty" := _Customertrend."Shipper Qty";
            InsertedSL.Insert(true);
        end;
    end;

    local procedure GetLastLineNo(HeaderNo: Code[20]): Integer
    var
        L_SalesLine: Record "Sales Line";
    begin
        L_SalesLine.RESET;
        L_SalesLine.SETRANGE("Document Type", L_SalesLine."Document Type"::Order);
        L_SalesLine.SETRANGE("Document No.", HeaderNo);
        IF L_SalesLine.FINDLAST THEN
            EXIT(L_SalesLine."Line No." + 10000)
        ELSE
            EXIT(10000);
    end;


    procedure CheckKnaapCustomer(_CustomerNo: Code[20]): Boolean
    var
        L_Customer: Record Customer;
    begin
        if L_Customer.Get(_CustomerNo) then
            if L_Customer."Knapp Customer" = true then
                exit(true);
        exit(false);
    end;

    procedure CheckKnaapItem(_ItemNo: Code[20]): Boolean
    var
        L_Item: Record Item;
    begin
        if L_Item.Get(_ItemNo) then
            if L_Item."Knapp Item" = true then
                exit(true);
        exit(false);
    end;

    procedure CheckKnaapShippingAgentService(_SalesHeader: Record "Sales Header"): Boolean
    var
        L_ShippingAgentService: Record "Shipping Agent Services";
    begin
        if (_SalesHeader."Shipping Agent Code" <> '') AND (_SalesHeader."Shipping Agent Service Code" <> '') then begin
            L_ShippingAgentService.Reset();
            L_ShippingAgentService.SetRange("Shipping Agent Code", _SalesHeader."Shipping Agent Code");
            L_ShippingAgentService.SetRange(Code, _SalesHeader."Shipping Agent Service Code");
            if L_ShippingAgentService.FindFirst() then begin
                if L_ShippingAgentService."Knapp Round" = true then
                    exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure GetBinCodeFromBincontent(_SalesLine: Record "Sales Line"; _SalesHeader: Record "Sales Header"; _Zone: Record Zone): Code[20]
    var
        L_BinContent: Record "Bin Content";
        L_Bin: Record Bin;
        L_Item: Record Item;
    begin
        L_BinContent.Reset();
        L_BinContent.SetRange("Location Code", _SalesHeader."Location Code");
        L_BinContent.SetRange("Zone Code", _Zone.Code);
        L_BinContent.SetRange("Item No.", _SalesLine."No.");
        L_BinContent.SetRange("Unit of Measure Code", _SalesLine."Unit of Measure Code");
        L_BinContent.SetFilter("Quantity (Base)", '>%1', 0);
        if L_Item.Get(_SalesLine."No.") then
            if L_Item."Warehouse Class Code" <> '' then
                L_BinContent.SetRange("Warehouse Class Code", L_Item."Warehouse Class Code");
        if L_BinContent.FindFirst() then begin
            if L_BinContent.CalcQtyAvailToTakeUOM() > 0 then begin
                exit(L_BinContent."Bin Code")
            end;
        end else begin
            L_Bin.Reset();
            L_Bin.SetRange("Location Code", _SalesHeader."Location Code");
            L_Bin.SetRange("Zone Code", _Zone.Code);
            L_Bin.SetRange(Empty, false);
            if L_Bin.FindFirst() then begin
                exit(L_Bin.Code)
            end;
        end;
    end;
}