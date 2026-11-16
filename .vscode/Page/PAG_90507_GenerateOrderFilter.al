page 90507 "Generate Order Filter"
{
    PageType = StandardDialog;
    UsageCategory = Administration;
    SourceTable = "Order Filter Table";

    layout
    {
        area(Content)
        {
            group("Sales Details")
            {
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    trigger OnValidate()
                    var
                    begin
                        if Rec."Shipment Date" = 0D then
                            Error('Please enter a valid Shipment Date');
                        if (Rec."Shipment Date" <> 0D) and (Rec.Shift <> Rec.Shift::" ") then begin
                            CalculateOrderDetails(Rec);
                        end;
                    end;
                }
                field(Shift; Rec.Shift)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    trigger OnValidate()
                    var
                    begin
                        if Rec.Shift = Rec.Shift::" " then
                            Error('Please choose a valid Shift');
                        if (Rec."Shipment Date" <> 0D) and (Rec.Shift <> Rec.Shift::" ") then begin
                            CalculateOrderDetails(Rec);
                        end;
                    end;
                }
                group("Process Orders Details")
                {
                    field("No. of Orders to Process"; Rec."No. of Orders to Process")
                    {
                        ApplicationArea = All;
                        ShowMandatory = true;
                        trigger OnValidate()
                        var
                        begin
                            if (Rec."No. of Orders to Process" = 0) or (Rec."No. of Orders to Process" < 0) then
                                Error('Please choose a valid number');
                            if Rec."No. of Orders to Process" > TotalOrderCount then
                                Error('You can not process orders more than Total No. of Orders');
                            CalculateTotalProcesOrderDetails(Rec);
                        end;
                    }
                    field(TotalOrderLinesToProcess; TotalOrderLinesToProcess)
                    {
                        Caption = 'No. of Lines to Process';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(TotalOrderQuantityToProcess; TotalOrderQuantityToProcess)
                    {
                        Caption = 'No. of Quantity to Process';
                        ApplicationArea = All;
                        Editable = false;
                    }
                }
                group("Total Orders Details")
                {
                    field(TotalOrderCount; TotalOrderCount)
                    {
                        Caption = 'Total Orders';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(TotalOrderLines; TotalOrderLines)
                    {
                        Caption = 'Total Order Lines';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(TotalOrderQuantity; TotalOrderQuantity)
                    {
                        Caption = 'Total Order Quantity';
                        ApplicationArea = All;
                        Editable = false;
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    var
    begin
        Clear(TotalOrderCount);
        Clear(TotalOrderLines);
        Clear(TotalOrderQuantity);
        Clear(TotalOrderLinesToProcess);
        Clear(TotalOrderQuantityToProcess);
    end;

    local procedure CalculateOrderDetails(var P_OrderFilterTable: Record "Order Filter Table")
    var
        L_SalesHeader: Record "Sales Header";
        L_SalesLine: Record "Sales Line";
        L_ShippingAgentServices: Record "Shipping Agent Services";
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        Clear(TotalOrderCount);
        Clear(TotalOrderLines);
        Clear(TotalOrderQuantity);
        Clear(P_OrderFilterTable."No. of Orders to Process");
        Clear(TotalOrderLinesToProcess);
        Clear(TotalOrderQuantityToProcess);
        Clear(L_SalesHeader);
        L_SalesHeader.Reset();
        L_SalesHeader.CalcFields("Sent to Knapp");
        L_SalesHeader.SetFilter("Document Type", '%1', L_SalesHeader."Document Type"::Order);
        L_SalesHeader.SetRange("Knapp Order", true);
        L_SalesHeader.SetRange("Shipment Date", Rec."Shipment Date");
        L_SalesHeader.SetRange("Sent to Knapp", false);
        L_SalesHeader.SetFilter(Status, '%1', L_SalesHeader.Status::Released);
        if L_SalesHeader.FindSet() then begin
            repeat
                Clear(ShippingAgentCode);
                if L_SalesHeader."Weekend Shipping Agent Code" <> '' then
                    ShippingAgentCode := CopyStr(L_SalesHeader."Weekend Shipping Agent Code", 1, 10)
                else
                    ShippingAgentCode := L_SalesHeader."Shipping Agent Code";

                Clear(ShippingAgentServiceCode);
                if L_SalesHeader."Weekend Ship. Agnt. Serv. Code" <> '' then
                    ShippingAgentServiceCode := L_SalesHeader."Weekend Ship. Agnt. Serv. Code"
                else
                    ShippingAgentServiceCode := L_SalesHeader."Shipping Agent Service Code";

                Clear(L_ShippingAgentServices);
                L_ShippingAgentServices.Reset();
                L_ShippingAgentServices.SetRange("Shipping Agent Code", ShippingAgentCode);
                L_ShippingAgentServices.SetRange(Code, ShippingAgentServiceCode);
                if L_ShippingAgentServices.FindFirst() then begin
                    if (L_ShippingAgentServices."Knapp Round" = true) and (Format(L_ShippingAgentServices.Shift) = Format(Rec.Shift)) then begin
                        TotalOrderCount += 1;

                        Clear(L_SalesLine);
                        L_SalesLine.Reset();
                        L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                        L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                        L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                        L_SalesLine.SetRange("Knapp Line", true);
                        L_SalesLine.SetRange("Sent to Knapp", false);
                        if L_SalesLine.FindSet() then begin
                            TotalOrderLines += L_SalesLine.Count;
                            L_SalesLine.CalcSums(Quantity);
                            TotalOrderQuantity += L_SalesLine.Quantity;
                        end;
                    end;
                end;
            until L_SalesHeader.Next() = 0;
        end;
    end;

    local procedure CalculateTotalProcesOrderDetails(var P_OrderFilterTable: Record "Order Filter Table")
    var
        L_SalesHeader: Record "Sales Header";
        L_SalesLine: Record "Sales Line";
        L_ShippingAgentServices: Record "Shipping Agent Services";
        Counter: Integer;
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        Clear(TotalOrderLinesToProcess);
        Clear(TotalOrderQuantityToProcess);
        Clear(Counter);
        Clear(L_SalesHeader);
        L_SalesHeader.Reset();
        L_SalesHeader.CalcFields("Sent to Knapp");
        L_SalesHeader.SetFilter("Document Type", '%1', L_SalesHeader."Document Type"::Order);
        L_SalesHeader.SetRange("Knapp Order", true);
        L_SalesHeader.SetRange("Shipment Date", Rec."Shipment Date");
        L_SalesHeader.SetRange("Sent to Knapp", false);
        L_SalesHeader.SetFilter(Status, '%1', L_SalesHeader.Status::Released);
        if L_SalesHeader.FindSet() then begin
            repeat
                Clear(ShippingAgentCode);
                if L_SalesHeader."Weekend Shipping Agent Code" <> '' then
                    ShippingAgentCode := CopyStr(L_SalesHeader."Weekend Shipping Agent Code", 1, 10)
                else
                    ShippingAgentCode := L_SalesHeader."Shipping Agent Code";

                Clear(ShippingAgentServiceCode);
                if L_SalesHeader."Weekend Ship. Agnt. Serv. Code" <> '' then
                    ShippingAgentServiceCode := L_SalesHeader."Weekend Ship. Agnt. Serv. Code"
                else
                    ShippingAgentServiceCode := L_SalesHeader."Shipping Agent Service Code";

                Clear(L_ShippingAgentServices);
                L_ShippingAgentServices.Reset();
                L_ShippingAgentServices.SetRange("Shipping Agent Code", ShippingAgentCode);
                L_ShippingAgentServices.SetRange(Code, ShippingAgentServiceCode);
                if L_ShippingAgentServices.FindFirst() then begin
                    if (L_ShippingAgentServices."Knapp Round" = true) and (Format(L_ShippingAgentServices.Shift) = Format(Rec.Shift)) then begin
                        Counter += 1;

                        Clear(L_SalesLine);
                        L_SalesLine.Reset();
                        L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                        L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                        L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                        L_SalesLine.SetRange("Knapp Line", true);
                        L_SalesLine.SetRange("Sent to Knapp", false);
                        if L_SalesLine.FindSet() then begin
                            TotalOrderLinesToProcess += L_SalesLine.Count;
                            L_SalesLine.CalcSums(Quantity);
                            TotalOrderQuantityToProcess += L_SalesLine.Quantity;
                        end;

                        if Counter = Rec."No. of Orders to Process" then
                            exit;
                    end;
                end;
            until L_SalesHeader.Next() = 0;
        end;
    end;

    var
        TotalOrderCount: Integer;
        TotalOrderLines: Integer;
        TotalOrderQuantity: Integer;
        TotalOrderLinesToProcess: Integer;
        TotalOrderQuantityToProcess: Integer;
}