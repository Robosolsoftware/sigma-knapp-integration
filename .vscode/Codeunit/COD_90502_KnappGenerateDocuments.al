codeunit 90502 "Knapp Generate Documents"
{
    TableNo = "Job Queue Entry";
    trigger OnRun()
    begin
        RunType := Rec."Parameter String";

        CASE RunType OF
            ArticleMasterLabel:
                begin
                    GenerateArticleMaster();
                end;
            CustomerMasterLabel:
                begin
                    GenerateCustomerMaster();
                end;
            RouteMasterLabel:
                begin
                    GenerateRouteMaster();
                end;
            OrderResponseLabel:
                begin
                    G_KnappDocumentQueue.Reset();
                    G_KnappDocumentQueue.SetFilter("Document Type", '%1', G_KnappDocumentQueue."Document Type"::"Order Update");
                    G_KnappDocumentQueue.SetFilter("Document Reference No.", '<>%1', '');
                    G_KnappDocumentQueue.SetFilter(Status, '%1', G_KnappDocumentQueue.Status::New);
                    G_KnappDocumentQueue.SetFilter(Request, '<>%1', '');
                    if G_KnappDocumentQueue.FindSet() then begin
                        repeat
                            SyncOrderResponses(G_KnappDocumentQueue);
                        until G_KnappDocumentQueue.Next() = 0;
                    end;
                end;
            GenerateOrdersLabel:
                begin
                    GenerateOrdersAutomated();
                end;
        end;
    end;

    var
        RunType: Text;
        ArticleMasterLabel: Label 'ArticleMaster';
        CustomerMasterLabel: Label 'CustomerMaster';
        RouteMasterLabel: Label 'RouteMaster';
        OrderResponseLabel: Label 'OrderResponse';
        GenerateOrdersLabel: Label 'GenerateOrders';
        G_KnappDocumentQueue: Record "Knapp Document Queue";
        Rec_KnappDocumentQueue: Record "Knapp Document Queue";
        ArticleRequest: Text;
        StationNo: Code[3];
        Aisle: Code[3];
        Rack: Code[3];
        RackLevel: Code[3];
        Position: Code[3];
        ArticleNo: Text[20];
        PackSize: Code[4];
        Length: Code[4];
        Width: Code[4];
        Height: Code[4];
        Weight: Code[6];
        ArticleCode: Text[14];
        ArticleName: Text[40];
        StorageLocation: Text[12];
        EjectionNo: Code[2];
        MaximumQty: Text;
        MinimumStock: Text;
        MaximumStock: Text;
        OverstockStorageLocation: Text[12];
        CustomerRequest: Text;
        CustomerNo: Text[12];
        CustomerName: Text[30];
        CustomerStreet: Text[30];
        CustomerCity: Text[30];
        CustomerPostCode: Text[10];
        CustomerAdditionalText: Text[40];
        RouteRequest: Text;
        RouteNumber: Text[8];
        DepartureTime: Text[6];
        OrderRequest: Text;
        ArticleType: Text;
        OrderNumber: Text[10];
        CheckOrderExist: Boolean;
        OrderCustomerNo: Text[12];
        OrderRouteNo: Text[8];
        TotalOrderLineNo: Text[3];
        TotalOrderStations: Integer;
        TotalStations: Code[2];
        OrderStationRequest: Text;
        NoOfRecs: Integer;
        ProgressCount: Integer;
        Count: Integer;


    procedure GenerateArticleMaster()
    var
        L_Item: Record Item;
        L_ItemReference: Record "Item Reference";
        L_KnappStationNo: Record "Knapp Station Numbers";
        L_KnappItemDetails: Record "Knapp Item Details";
        L_KnappItemDimensions: Record "Knapp Item Dimensions";
        DocumentReference: Text;
        IsArticleExist: Boolean;
        EntryInserted: Boolean;
        L_ItemVariant: Record "Item Variant";
        IsItemVariantMandatory: Boolean;
    begin
        L_ItemReference.Reset();
        L_ItemReference.SetRange(Knapp, true);
        L_ItemReference.SetRange("Sent to Knapp", false);
        //L_ItemReference.SetFilter("Item No.", '%1', 'HYLO-TEAR');
        L_ItemReference.SetFilter("Item No.", '<>%1', '');
        L_ItemReference.SetFilter("Reference Type", '%1', L_ItemReference."Reference Type"::"Article Number");
        if L_ItemReference.FindSet() then begin
            repeat
                IsItemVariantMandatory := false;
                L_Item.Reset();
                if L_Item.Get(L_ItemReference."Item No.") then begin
                    L_Item.CalcFields("Variant Exist");
                    if L_Item."Variant Exist" = true then begin
                        if L_ItemReference."Variant Code" <> '' then
                            IsItemVariantMandatory := true;
                    end
                    else begin
                        IsItemVariantMandatory := true;
                    end;
                end;

                if IsItemVariantMandatory = true then begin
                    EntryInserted := false;
                    L_KnappItemDetails.Reset();
                    L_KnappItemDetails.SetRange("Item No.", L_ItemReference."Item No.");
                    L_KnappItemDetails.SetRange("Item Reference No.", L_ItemReference."Reference No.");
                    L_KnappItemDetails.SetRange("Item Reference Type", L_ItemReference."Reference Type");
                    if L_ItemReference."Variant Code" <> '' then
                        L_KnappItemDetails.SetRange("Item Variant Code", L_ItemReference."Variant Code");
                    if L_KnappItemDetails.FindSet() then begin
                        repeat
                            L_KnappItemDimensions.Reset();
                            L_KnappItemDimensions.SetRange("Item No.", L_ItemReference."Item No.");
                            L_KnappItemDimensions.SetRange("Item Reference No.", L_ItemReference."Reference No.");
                            L_KnappItemDimensions.SetRange("Item Reference Type", L_ItemReference."Reference Type");
                            L_KnappItemDimensions.SetFilter("Pack Size", '%1', L_KnappItemDetails."Knapp Pack Size");
                            if L_ItemReference."Variant Code" <> '' then
                                L_KnappItemDimensions.SetRange("Item Variant Code", L_ItemReference."Variant Code");
                            if L_KnappItemDimensions.FindFirst() then begin
                                ClearArticleMasterVariables();

                                #Region Getting Data for Knapp Article
                                StationNo := L_KnappItemDetails."Knapp Station Number";
                                Aisle := Format(L_KnappItemDetails."Knapp Aisle");
                                Rack := Format(L_KnappItemDetails."Knapp Rack");
                                RackLevel := Format(L_KnappItemDetails."Knapp Rack Level");
                                Position := Format(L_KnappItemDetails."Knapp Position");
                                ArticleCode := CopyStr(L_ItemReference."Reference No.", 1, 14);
                                PackSize := Format(L_KnappItemDetails."Knapp Pack Size");
                                Length := Format(L_KnappItemDimensions.Length, 4);
                                Width := Format(L_KnappItemDimensions.Width, 4);
                                Height := Format(L_KnappItemDimensions.Height, 4);
                                Weight := Format(L_KnappItemDimensions.Weight, 6, '<Integer>');
                                StorageLocation := L_KnappItemDetails."Knapp Storage Location";
                                EjectionNo := L_KnappItemDetails."Knapp Ejection No";
                                MaximumQty := Format(L_KnappItemDetails."Maximum ACS Quantity", 4, '<Integer>');
                                MaximumStock := Format(L_KnappItemDetails."Knapp Maximum Stock", 4, '<Integer>');
                                MinimumStock := Format(L_KnappItemDetails."Knapp Minimum Stock", 4, '<Integer>');
                                OverstockStorageLocation := L_KnappItemDetails."Overstock Storage Location";
                                if L_ItemReference."Variant Code" <> '' then
                                    ArticleNo := L_ItemReference."Variant Code"
                                else
                                    ArticleNo := L_ItemReference."Item No.";

                                L_KnappStationNo.Reset();
                                L_KnappStationNo.SetRange("Station Number", StationNo);
                                if L_KnappStationNo.FindFirst() then begin
                                    ArticleType := Format(L_KnappStationNo.Type);
                                end;

                                ArticleName := CopyStr(L_ItemReference."Description 2", 1, 40);
                                if ArticleName = '' then begin
                                    if L_ItemReference."Variant Code" <> '' then begin
                                        Clear(L_ItemVariant);
                                        L_ItemVariant.Reset();
                                        L_ItemVariant.SetRange("Item No.", L_ItemReference."Item No.");
                                        L_ItemVariant.SetRange(Code, L_ItemReference."Variant Code");
                                        if L_ItemVariant.FindFirst() then begin
                                            ArticleName := CopyStr(L_ItemVariant.Description, 1, 40);
                                        end;
                                    end;

                                    Clear(L_Item);
                                    L_Item.Reset();
                                    L_Item.SetRange("No.", L_ItemReference."Item No.");
                                    if L_Item.FindFirst() then begin
                                        ArticleName := CopyStr(L_Item.Description, 1, 40);
                                    end;
                                end;
                                #endregion

                                #Region Data Record Identifier
                                if StrLen(StationNo) < 3 then begin
                                    repeat
                                        StationNo := '0' + StationNo;
                                    until StrLen(StationNo) = 3;
                                end;

                                if StrLen(Aisle) < 3 then begin
                                    repeat
                                        Aisle := '0' + Aisle;
                                    until StrLen(Aisle) = 3;
                                end;

                                if StrLen(Rack) < 3 then begin
                                    repeat
                                        Rack := '0' + Rack;
                                    until StrLen(Rack) = 3;
                                end;

                                if StrLen(RackLevel) < 3 then begin
                                    repeat
                                        RackLevel := '0' + RackLevel;
                                    until StrLen(RackLevel) = 3;
                                end;

                                if StrLen(Position) < 3 then begin
                                    repeat
                                        Position := '0' + Position;
                                    until StrLen(Position) = 3;
                                end;

                                if ArticleType = 'Manual Station' then begin
                                    ArticleRequest := '14N030303030300' + StationNo + Aisle + Rack + RackLevel + Position;
                                end
                                else begin
                                    ArticleRequest := '14N030003030300' + StationNo + Rack + RackLevel + Position;
                                end;
                                #endregion

                                #Region Article number / pack size identifier
                                if StrLen(ArticleNo) < 20 then begin
                                    repeat
                                        ArticleNo := ' ' + ArticleNo;
                                    until StrLen(ArticleNo) = 20;
                                end;

                                if StrLen(PackSize) < 4 then begin
                                    repeat
                                        PackSize := '0' + PackSize;
                                    until StrLen(PackSize) = 4;
                                end;

                                ArticleRequest += 'L2004' + ArticleNo + PackSize;
                                #endregion

                                #Region Ejection number identifier
                                if StrLen(EjectionNo) < 2 then begin
                                    repeat
                                        EjectionNo := '0' + EjectionNo;
                                    until StrLen(EjectionNo) = 2;
                                end;
                                if ArticleType <> 'Manual Station' then begin
                                    ArticleRequest += 'Y02' + EjectionNo;
                                end;
                                #endregion

                                #Region Maximum quantity identifier
                                if MaximumQty.Contains(',') then
                                    MaximumQty := MaximumQty.Replace(',', '');
                                if StrLen(MaximumQty) < 4 then begin
                                    repeat
                                        MaximumQty := '0' + MaximumQty;
                                    until StrLen(MaximumQty) = 4;
                                end;
                                if ArticleType <> 'Manual Station' then begin
                                    ArticleRequest += 'M04' + MaximumQty;
                                end;
                                #endregion

                                #Region Dimensions identifier
                                if StrLen(Length) < 4 then begin
                                    repeat
                                        Length := '0' + Length;
                                    until StrLen(Length) = 4;
                                end;

                                if StrLen(Width) < 4 then begin
                                    repeat
                                        Width := '0' + Width;
                                    until StrLen(Width) = 4;
                                end;

                                if StrLen(Height) < 4 then begin
                                    repeat
                                        Height := '0' + Height;
                                    until StrLen(Height) = 4;
                                end;

                                ArticleRequest += 'D040404' + Length + Width + Height;
                                #endregion

                                #Region Weight identifier
                                if StrLen(Weight) < 6 then begin
                                    repeat
                                        Weight := '0' + Weight;
                                    until StrLen(Weight) = 6;
                                end;

                                ArticleRequest += 'G06' + Weight;
                                #endregion

                                #Region Article code identifier
                                if StrLen(ArticleCode) < 14 then begin
                                    repeat
                                        ArticleCode += ' ';
                                    until StrLen(ArticleCode) = 14;
                                end;

                                ArticleRequest += 'B0114' + ArticleCode;
                                #endregion

                                #Region Article name identifier
                                if StrLen(ArticleName) < 40 then begin
                                    repeat
                                        ArticleName := ' ' + ArticleName;
                                    until StrLen(ArticleName) = 40;
                                end;

                                if StrLen(StorageLocation) < 12 then begin
                                    repeat
                                        StorageLocation := ' ' + StorageLocation;
                                    until StrLen(StorageLocation) = 12;
                                end;

                                ArticleRequest += 'K4012' + ArticleName + StorageLocation;
                                #endregion

                                #Region Stock limits identifier
                                if StrLen(MinimumStock) < 4 then begin
                                    repeat
                                        MinimumStock := '0' + MinimumStock;
                                    until StrLen(MinimumStock) = 4;
                                end;

                                if StrLen(MaximumStock) < 4 then begin
                                    repeat
                                        MaximumStock := '0' + MaximumStock;
                                    until StrLen(MaximumStock) = 4;
                                end;
                                if ArticleType <> 'Manual Station' then begin
                                    ArticleRequest += 'S0404' + MinimumStock + MaximumStock;
                                end;

                                #endregion

                                #Region Overstock storage location identifier
                                if StrLen(OverstockStorageLocation) < 12 then begin
                                    repeat
                                        OverstockStorageLocation := ' ' + OverstockStorageLocation;
                                    until StrLen(OverstockStorageLocation) = 12;
                                end;
                                if ArticleType <> 'Manual Station' then begin
                                    ArticleRequest += 'T0312' + GetOverstockStation(L_KnappItemDetails) + OverstockStorageLocation;
                                end;
                                #endregion

                                #Region Inserting Entry in Knapp Document Queue Table
                                //The Seperator Symbol is Long Dash (—)
                                Clear(DocumentReference);
                                DocumentReference := L_ItemReference."Item No." + '—' + L_ItemReference."Reference No." + '—' +
                                Format(L_KnappItemDetails."Entry No.") + '—' + Format(L_KnappItemDimensions."Entry No.");

                                IsArticleExist := false;
                                IsArticleExist := CheckArticleExist(DocumentReference);

                                if IsArticleExist = false then begin
                                    Clear(G_KnappDocumentQueue);
                                    G_KnappDocumentQueue.Reset();
                                    G_KnappDocumentQueue.Init();

                                    Clear(Rec_KnappDocumentQueue);
                                    Rec_KnappDocumentQueue.Reset();
                                    if Rec_KnappDocumentQueue.FindLast() then
                                        G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
                                    else
                                        G_KnappDocumentQueue."Entry No." := 1;

                                    G_KnappDocumentQueue."User ID" := UserId;
                                    G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Article Master";
                                    G_KnappDocumentQueue.Update := true;
                                    G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
                                    G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
                                    G_KnappDocumentQueue.Request := CopyStr(ArticleRequest, 1, 2048);
                                    G_KnappDocumentQueue."Document Reference No." := DocumentReference;

                                    G_KnappDocumentQueue.Insert();
                                    EntryInserted := true;
                                end
                                else begin
                                    if CheckArticleDeleteRequestExist(DocumentReference) = false then begin
                                        CreateArticleDeleteRequest(DocumentReference);
                                        if CheckArticleUpdateRequestExist(DocumentReference) = false then begin
                                            EntryInserted := CreateArticleUpdateRequest(DocumentReference, ArticleRequest);
                                        end;
                                    end
                                    else begin
                                        if CheckArticleUpdateRequestExist(DocumentReference) = false then begin
                                            EntryInserted := CreateArticleUpdateRequest(DocumentReference, ArticleRequest);
                                        end;
                                    end;
                                end;
                                #endregion
                            end;
                        until L_KnappItemDetails.Next() = 0;
                    end;

                    if EntryInserted = true then
                        L_ItemReference."Sent to Knapp" := true;
                    L_ItemReference.Modify();
                    Commit();
                end;
            until L_ItemReference.Next() = 0;
        end;
    end;

    local procedure GetOverstockStation(P_KnappItemDetails: Record "Knapp Item Details"): Text
    var
        KnappDetails: Record "Knapp Item Details";
    begin
        KnappDetails.Reset();
        KnappDetails.SetFilter("Item No.", P_KnappItemDetails."Item No.");
        KnappDetails.SetFilter("Item Reference No.", P_KnappItemDetails."Item Reference No.");
        KnappDetails.SetFilter("Item Variant Code", P_KnappItemDetails."Item Variant Code");
        KnappDetails.SetFilter("Knapp Storage Location", P_KnappItemDetails."Overstock Storage Location");
        if KnappDetails.FindFirst() then begin
            exit(KnappDetails."Knapp Station Number");
        end;
    end;

    local procedure CheckArticleExist(DocumentReference: Text): Boolean
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter("Document Type", '%1', L_KnappDocumentQueue."Document Type"::"Article Master");
        L_KnappDocumentQueue.SetFilter(Status, '%1|%2', L_KnappDocumentQueue.Status::New, L_KnappDocumentQueue.Status::Completed);
        L_KnappDocumentQueue.SetFilter("Document Reference No.", DocumentReference);
        if L_KnappDocumentQueue.FindFirst() then
            exit(true);
    end;

    local procedure CheckArticleDeleteRequestExist(DocumentReference: Text): Boolean
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter("Document Type", '%1', L_KnappDocumentQueue."Document Type"::"Article Delete");
        L_KnappDocumentQueue.SetFilter(Status, '%1', L_KnappDocumentQueue.Status::New);
        L_KnappDocumentQueue.SetFilter("Document Reference No.", DocumentReference);
        if L_KnappDocumentQueue.FindFirst() then
            exit(true);
    end;

    local procedure CheckArticleUpdateRequestExist(DocumentReference: Text): Boolean
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter("Document Type", '%1', L_KnappDocumentQueue."Document Type"::"Article Update");
        L_KnappDocumentQueue.SetFilter(Status, '%1', L_KnappDocumentQueue.Status::New);
        L_KnappDocumentQueue.SetFilter("Document Reference No.", DocumentReference);
        if L_KnappDocumentQueue.FindFirst() then
            exit(true);
    end;

    local procedure CreateArticleDeleteRequest(DocumentReference: Text)
    var
        ArticleDeleteRequest: Text;
    begin
        Clear(ArticleDeleteRequest);
        ArticleDeleteRequest := '14D200403' + ArticleNo + PackSize + StationNo;

        Clear(G_KnappDocumentQueue);
        G_KnappDocumentQueue.Reset();
        G_KnappDocumentQueue.Init();

        Clear(Rec_KnappDocumentQueue);
        Rec_KnappDocumentQueue.Reset();
        if Rec_KnappDocumentQueue.FindLast() then
            G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
        else
            G_KnappDocumentQueue."Entry No." := 1;

        G_KnappDocumentQueue."User ID" := UserId;
        G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Article Delete";
        G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
        G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
        G_KnappDocumentQueue.Request := CopyStr(ArticleDeleteRequest, 1, 2048);
        G_KnappDocumentQueue."Document Reference No." := DocumentReference;

        G_KnappDocumentQueue.Insert();
    end;

    local procedure CreateArticleUpdateRequest(DocumentReference: Text; ArticleRequest: Text): Boolean
    var
    begin
        Clear(G_KnappDocumentQueue);
        G_KnappDocumentQueue.Reset();
        G_KnappDocumentQueue.Init();

        Clear(Rec_KnappDocumentQueue);
        Rec_KnappDocumentQueue.Reset();
        if Rec_KnappDocumentQueue.FindLast() then
            G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
        else
            G_KnappDocumentQueue."Entry No." := 1;

        G_KnappDocumentQueue."User ID" := UserId;
        G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Article Update";
        G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
        G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
        G_KnappDocumentQueue.Request := CopyStr(ArticleRequest, 1, 2048);
        G_KnappDocumentQueue."Document Reference No." := DocumentReference;

        G_KnappDocumentQueue.Insert();
        exit(true);
    end;

    procedure GenerateCustomerMaster()
    var
        L_Customer: Record Customer;
        Windows: Dialog;
        Text001: TextConst ENU = 'Generating Customer Masters..';
    begin
        Windows.OPEN(Text001 + ' @1@@@@@@@@@@@@@\' + 'Customer Master Sync..' + ' #3##########' + 'Please Wait..');
        L_Customer.Reset();
        L_Customer.SetRange(Blocked, L_Customer.Blocked::" ");
        L_Customer.SetFilter(Name, '<>%1', '');
        L_Customer.SetRange("Knapp Customer", true);
        L_Customer.SetRange("Sent to Knapp", false);
        if L_Customer.FindSet() then begin
            NoOfRecs := L_Customer.Count;
            repeat
                ClearCustomerMasterVariables();

                ProgressCount += 1;
                IF NoOfRecs <= 100 THEN
                    Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1)
                ELSE
                    IF Count MOD (NoOfRecs DIV 100) = 0 THEN
                        Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1);
                Windows.UPDATE(3, L_Customer."No.");

                #Region Data record identifier
                CustomerNo := CopyStr(L_Customer."No.", 1, 12);
                if StrLen(CustomerNo) < 12 then begin
                    repeat
                        CustomerNo += ' ';
                    until StrLen(CustomerNo) = 12;
                end;

                CustomerRequest := '15N12' + CustomerNo;
                #endregion

                #Region Identifier for customer name 1
                CustomerName := CopyStr(L_Customer.Name, 1, 30);
                if StrLen(CustomerName) < 30 then begin
                    repeat
                        CustomerName += ' ';
                    until StrLen(CustomerName) = 30;
                end;

                CustomerRequest += 'N30' + CustomerName;
                #endregion

                #Region Street identifier
                CustomerStreet := CopyStr(L_Customer.Address, 1, 30);
                if StrLen(CustomerStreet) < 30 then begin
                    repeat
                        CustomerStreet += ' ';
                    until StrLen(CustomerStreet) = 30;
                end;

                CustomerRequest += 'S30' + CustomerStreet;
                #endregion

                #Region City/town identifier
                CustomerCity := CopyStr(L_Customer.City, 1, 30);
                if StrLen(CustomerCity) < 30 then begin
                    repeat
                        CustomerCity += ' ';
                    until StrLen(CustomerCity) = 30;
                end;

                CustomerRequest += 'P30' + CustomerCity;
                #endregion

                #Region Post code identifier (Note - In the Document it is written 6 Characters but actually Knapp Accepts 10 Characters)
                CustomerPostCode := CopyStr(L_Customer."Post Code", 1, 10);
                if StrLen(CustomerPostCode) < 10 then begin
                    repeat
                        CustomerPostCode += ' ';
                    until StrLen(CustomerPostCode) = 10;
                end;

                CustomerRequest += 'Z10' + CustomerPostCode;
                #endregion

                #Region Additional text identifier
                if StrLen(CustomerAdditionalText) < 40 then begin
                    repeat
                        CustomerAdditionalText += ' ';
                    until StrLen(CustomerAdditionalText) = 40;
                end;

                CustomerRequest += 'T40' + CustomerAdditionalText;
                #endregion

                #Region Inserting Entry in Knapp Document Queue Table
                Clear(G_KnappDocumentQueue);
                G_KnappDocumentQueue.Reset();
                G_KnappDocumentQueue.Init();

                Rec_KnappDocumentQueue.Reset();
                if Rec_KnappDocumentQueue.FindLast() then
                    G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
                else
                    G_KnappDocumentQueue."Entry No." := 1;

                if CheckCustomerExist(L_Customer) = false then begin
                    G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Customer Master";
                    G_KnappDocumentQueue.Update := true;
                end
                else
                    G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Customer Update";

                G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
                G_KnappDocumentQueue."User ID" := UserId;
                G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
                G_KnappDocumentQueue.Request := CopyStr(CustomerRequest, 1, 2048);
                G_KnappDocumentQueue."Document Reference No." := L_Customer."No.";
                G_KnappDocumentQueue.Insert();
                #endregion

                L_Customer."Sent to Knapp" := true;
                L_Customer.Modify();
                Commit();
            until L_Customer.Next() = 0;
        end;
    end;

    local procedure CheckCustomerExist(var P_Customer: Record Customer): Boolean
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter("Document Type", '%1', L_KnappDocumentQueue."Document Type"::"Customer Master");
        L_KnappDocumentQueue.SetFilter(Status, '%1|%2', L_KnappDocumentQueue.Status::New, L_KnappDocumentQueue.Status::Completed);
        L_KnappDocumentQueue.SetFilter("Document Reference No.", P_Customer."No.");
        if L_KnappDocumentQueue.FindFirst() then
            exit(true);
    end;

    //Route Master is nothing but "Round Numbers" which is "Shipping Agent Services" in Business Central
    procedure GenerateRouteMaster()
    var
        L_ShippingAgentServices: Record "Shipping Agent Services";
        Windows: Dialog;
        Text001: TextConst ENU = 'Generating Route Masters..';
    begin
        Windows.OPEN(Text001 + ' @1@@@@@@@@@@@@@\' + 'Route Master Sync..' + ' #3##########' + 'Please Wait..');
        L_ShippingAgentServices.Reset();
        L_ShippingAgentServices.SetRange("Knapp Round", true);
        L_ShippingAgentServices.SetRange("Sent to Knapp", false);
        if L_ShippingAgentServices.FindSet() then begin
            NoOfRecs := L_ShippingAgentServices.Count;
            repeat
                ClearRouteMasterVariables();

                ProgressCount += 1;
                IF NoOfRecs <= 100 THEN
                    Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1)
                ELSE
                    IF Count MOD (NoOfRecs DIV 100) = 0 THEN
                        Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1);
                Windows.UPDATE(3, L_ShippingAgentServices.Code);

                #Region Data record identifier
                RouteNumber := CopyStr(L_ShippingAgentServices.Code, 1, 8);
                if StrLen(RouteNumber) < 8 then begin
                    repeat
                        RouteNumber += ' ';
                    until StrLen(RouteNumber) = 8;
                end;

                RouteRequest := '16N08' + RouteNumber;
                #endregion

                #Region Departure time identifier
                DepartureTime := Format(L_ShippingAgentServices."Departure Time", 0, '<Hours24,2><Minutes,2><Seconds,2>');

                if DepartureTime = ' 00000' then begin
                    DepartureTime := '000000';
                end;

                if DepartureTime.StartsWith(' ') then
                    DepartureTime := DepartureTime.TrimStart(' ');

                if StrLen(DepartureTime) < 6 then begin
                    repeat
                        DepartureTime := '0' + DepartureTime;
                    until StrLen(DepartureTime) = 6;
                end;

                RouteRequest += 'Z0600' + DepartureTime;
                #endregion

                #Region Inserting Entry in Knapp Document Queue Table
                Clear(G_KnappDocumentQueue);
                G_KnappDocumentQueue.Reset();
                G_KnappDocumentQueue.Init();

                Rec_KnappDocumentQueue.Reset();
                if Rec_KnappDocumentQueue.FindLast() then
                    G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
                else
                    G_KnappDocumentQueue."Entry No." := 1;

                if CheckRouteExist(L_ShippingAgentServices) = false then begin
                    G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Route Master";
                    G_KnappDocumentQueue.Update := true;
                end
                else
                    G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Route Update";

                G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
                G_KnappDocumentQueue."User ID" := UserId;
                G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
                G_KnappDocumentQueue.Request := CopyStr(RouteRequest, 1, 2048);
                G_KnappDocumentQueue."Document Reference No." := L_ShippingAgentServices.Code;
                G_KnappDocumentQueue.Insert();
                #endregion

                L_ShippingAgentServices."Sent to Knapp" := true;
                L_ShippingAgentServices.Modify();
                Commit();
            until L_ShippingAgentServices.Next() = 0;
        end;
    end;

    local procedure CheckRouteExist(var P_ShippingAgentService: Record "Shipping Agent Services"): Boolean
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter("Document Type", '%1', L_KnappDocumentQueue."Document Type"::"Route Master");
        L_KnappDocumentQueue.SetFilter(Status, '%1|%2', L_KnappDocumentQueue.Status::New, L_KnappDocumentQueue.Status::Completed);
        L_KnappDocumentQueue.SetFilter("Document Reference No.", P_ShippingAgentService.Code);
        if L_KnappDocumentQueue.FindFirst() then
            exit(true);
    end;

    procedure GenerateOrders()
    var
        L_SalesHeader: Record "Sales Header";
        L_SalesLine: Record "Sales Line";
        Rec_SalesLine: Record "Sales Line";
        OrderLineRequest: Text;
        OrderArticleNumber: Text[20];
        L_Item: Record Item;
        TotalOrderLines: Integer;
        OrderLineQuantity: Text[4];
        OrderQuantity: Text;
        L_Customer: Record Customer;
        L_KnappStationNumbers: Record "Knapp Station Numbers";
        OrderFilter: Record "Order Filter Table" temporary;
        L_ShippingAgentServices: Record "Shipping Agent Services";
        CheckOrderDeleteExist: Boolean;
        NoOfOrders: Integer;
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        #Region Creating a Temporary Entry for Filter Popup Page
        OrderFilter.DeleteAll();
        OrderFilter.Init();
        OrderFilter."Primary key" := 'KNAPP';
        OrderFilter."Shipment Date" := 0D;
        OrderFilter.Shift := OrderFilter.Shift::E;
        OrderFilter."No. of Orders to Process" := 0;
        OrderFilter.Insert();
        #endregion

        if Page.RunModal(90507, OrderFilter) = Action::LookupOK then begin
            if OrderFilter."Shipment Date" = 0D then
                Error('Please enter a valid Shipment Date');
            if OrderFilter.Shift = OrderFilter.Shift::" " then
                Error('Please choose a valid Shift');
            if (OrderFilter."No. of Orders to Process" = 0) and (OrderFilter."No. of Orders to Process" < 0) then
                Error('Please choose a valid number');
            if Confirm(StrSubstNo('You have selected Shipment Date "%1" and Shift "%2". Are you sure you want to continue?', OrderFilter."Shipment Date", OrderFilter.Shift)) then begin
                NoOfOrders := 0;
                L_SalesLine.Reset();
                L_SalesLine.SetFilter("Document Type", '%1', L_SalesLine."Document Type"::Order);
                L_SalesLine.SetFilter(Type, '%1', L_SalesLine.Type::Item);
                L_SalesLine.SetRange("Knapp Line", true);
                L_SalesLine.SetRange("Sent to Knapp", false);
                L_SalesLine.SetFilter(Quantity, '>%1', 0);
                if L_SalesLine.FindSet() then begin
                    repeat
                        ClearOrderVariables();

                        L_SalesHeader.Reset();
                        L_SalesHeader.CalcFields("Sent to Knapp");
                        L_SalesHeader.SetFilter("Document Type", '%1', L_SalesHeader."Document Type"::Order);
                        L_SalesHeader.SetRange("No.", L_SalesLine."Document No.");
                        L_SalesHeader.SetRange("Knapp Order", true);
                        L_SalesHeader.SetRange("Sent Knapp Invoice", false);
                        L_SalesHeader.SetRange("Sent to Knapp", false);
                        L_SalesHeader.SetRange("Shipment Date", OrderFilter."Shipment Date");
                        L_SalesHeader.SetFilter(Status, '%1', L_SalesHeader.Status::Released);
                        if L_SalesHeader.FindFirst() then begin
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
                                if (L_ShippingAgentServices."Knapp Round" = true) and (Format(L_ShippingAgentServices.Shift) = Format(OrderFilter.Shift)) then begin
                                    OrderNumber := CopyStr(L_SalesHeader."No.", 1, 10);

                                    CheckOrderExist := false;
                                    CheckOrderExist := CheckOrderExistOrNot();

                                    CheckOrderDeleteExist := false;
                                    CheckOrderDeleteExist := CheckOrderDeleteExistOrNot();

                                    if (CheckOrderExist = false) and (CheckOrderDeleteExist = false) then begin
                                        #Region Data record identifier
                                        if StrLen(OrderNumber) < 10 then begin
                                            repeat
                                                OrderNumber := ' ' + OrderNumber;
                                            until StrLen(OrderNumber) = 10;
                                        end;

                                        OrderRequest := '12N1003' + OrderNumber + '000';
                                        #endregion

                                        #Region Order type identifier
                                        OrderRequest += 'T0210';
                                        #endregion

                                        #Region Customer number identifier
                                        OrderCustomerNo := CopyStr(L_SalesHeader."Sell-to Customer No.", 1, 12);
                                        if StrLen(OrderCustomerNo) < 12 then begin
                                            repeat
                                                OrderCustomerNo := ' ' + OrderCustomerNo;
                                            until StrLen(OrderCustomerNo) = 12;
                                        end;
                                        OrderRequest += 'E12' + OrderCustomerNo;
                                        #endregion

                                        #Region Route number identifier
                                        if L_SalesHeader."Weekend Ship. Agnt. Serv. Code" = '' then begin
                                            OrderRouteNo := CopyStr(L_SalesHeader."Shipping Agent Service Code", 1, 8);
                                        end
                                        else begin
                                            OrderRouteNo := CopyStr(L_SalesHeader."Weekend Ship. Agnt. Serv. Code", 1, 8);
                                        end;

                                        if StrLen(OrderRouteNo) < 8 then begin
                                            repeat
                                                OrderRouteNo := ' ' + OrderRouteNo;
                                            until StrLen(OrderRouteNo) = 8;
                                        end;
                                        OrderRequest += 'F08' + OrderRouteNo;
                                        #endregion

                                        #Region target stations identifier
                                        L_Customer.Reset();
                                        L_Customer.SetRange("No.", L_SalesHeader."Sell-to Customer No.");
                                        if L_Customer.FindFirst() then begin
                                            if L_Customer."Knapp Special Check" = true then begin
                                                L_KnappStationNumbers.Reset();
                                                L_KnappStationNumbers.SetFilter("Special Check", '%1', true);
                                                if L_KnappStationNumbers.FindFirst() then begin
                                                    TotalOrderStations += 1;
                                                    OrderStationRequest := L_KnappStationNumbers."Station Number";
                                                end;
                                            end;
                                            if L_Customer."Knapp Final Check" = true then begin
                                                L_KnappStationNumbers.Reset();
                                                L_KnappStationNumbers.SetFilter("Final Check", '%1', true);
                                                if L_KnappStationNumbers.FindFirst() then begin
                                                    TotalOrderStations += 1;
                                                    if OrderStationRequest = '' then
                                                        OrderStationRequest := L_KnappStationNumbers."Station Number"
                                                    else begin
                                                        OrderStationRequest += L_KnappStationNumbers."Station Number"
                                                    end;
                                                end;
                                            end;
                                            if L_Customer."Knapp Invoice Station" = true then begin
                                                L_KnappStationNumbers.Reset();
                                                L_KnappStationNumbers.SetFilter("Invoice Station", '%1', true);
                                                if L_KnappStationNumbers.FindFirst() then begin
                                                    TotalOrderStations += 1;
                                                    if OrderStationRequest = '' then
                                                        OrderStationRequest := L_KnappStationNumbers."Station Number"
                                                    else begin
                                                        OrderStationRequest += L_KnappStationNumbers."Station Number"
                                                    end;
                                                end;
                                            end;
                                            if L_Customer."Knapp Repack" = true then begin
                                                L_KnappStationNumbers.Reset();
                                                L_KnappStationNumbers.SetFilter(Repacking, '%1', true);
                                                if L_KnappStationNumbers.FindFirst() then begin
                                                    TotalOrderStations += 1;
                                                    if OrderStationRequest = '' then
                                                        OrderStationRequest := L_KnappStationNumbers."Station Number"
                                                    else begin
                                                        OrderStationRequest += L_KnappStationNumbers."Station Number"
                                                    end;
                                                end;
                                            end;
                                            if L_Customer."Knapp Lid" = true then begin
                                                L_KnappStationNumbers.Reset();
                                                L_KnappStationNumbers.SetFilter(Lid, '%1', true);
                                                if L_KnappStationNumbers.FindFirst() then begin
                                                    TotalOrderStations += 1;
                                                    if OrderStationRequest = '' then
                                                        OrderStationRequest := L_KnappStationNumbers."Station Number"
                                                    else begin
                                                        OrderStationRequest += L_KnappStationNumbers."Station Number"
                                                    end;
                                                end;
                                            end;

                                            TotalStations := Format(TotalOrderStations);
                                            if StrLen(TotalStations) < 2 then begin
                                                repeat
                                                    TotalStations := '0' + TotalStations;
                                                until StrLen(TotalStations) = 2;
                                            end;

                                            OrderRequest += 'K' + TotalStations + '03' + OrderStationRequest;
                                        end;
                                        #endregion

                                        #Region Order line identifier
                                        Clear(OrderLineRequest);
                                        TotalOrderLines := 0;
                                        Rec_SalesLine.Reset();
                                        Rec_SalesLine.SetFilter("Document Type", '%1', Rec_SalesLine."Document Type"::Order);
                                        Rec_SalesLine.SetFilter(Type, '%1', Rec_SalesLine.Type::Item);
                                        Rec_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                                        Rec_SalesLine.SetRange("Sent to Knapp", false);
                                        Rec_SalesLine.SetRange("Knapp Line", true);
                                        Rec_SalesLine.SetFilter(Quantity, '>%1', 0);
                                        if Rec_SalesLine.FindSet() then begin
                                            repeat
                                                Clear(OrderArticleNumber);
                                                Clear(OrderLineQuantity);
                                                Clear(OrderQuantity);
                                                Clear(L_Item);
                                                L_Item.Reset();
                                                L_Item.SetRange("No.", Rec_SalesLine."No.");
                                                if L_Item.FindFirst() then begin
                                                    if L_Item."Knapp Item" = true then begin
                                                        if Rec_SalesLine."Variant Code" <> '' then
                                                            OrderArticleNumber := Rec_SalesLine."Variant Code"
                                                        else
                                                            OrderArticleNumber := CopyStr(L_Item."No.", 1, 20);
                                                        if StrLen(OrderArticleNumber) < 20 then begin
                                                            repeat
                                                                OrderArticleNumber := ' ' + OrderArticleNumber;
                                                            until StrLen(OrderArticleNumber) = 20;
                                                        end;

                                                        OrderQuantity := Format(Rec_SalesLine.Quantity);
                                                        if OrderQuantity.Contains(',') then
                                                            OrderQuantity := OrderQuantity.Replace(',', '');
                                                        OrderLineQuantity := CopyStr(OrderQuantity, 1, 4);
                                                        if StrLen(OrderLineQuantity) < 4 then begin
                                                            repeat
                                                                OrderLineQuantity := '0' + OrderLineQuantity;
                                                            until StrLen(OrderLineQuantity) = 4;
                                                        end;

                                                        OrderLineRequest += OrderArticleNumber + OrderLineQuantity;
                                                        TotalOrderLines += 1;
                                                        Rec_SalesLine."Sent to Knapp" := true;
                                                        Rec_SalesLine.Remarks := '';
                                                        Rec_SalesLine.Modify();
                                                    end;
                                                end;
                                            until Rec_SalesLine.Next() = 0;

                                            TotalOrderLineNo := Format(TotalOrderLines);
                                            if StrLen(TotalOrderLineNo) < 3 then begin
                                                repeat
                                                    TotalOrderLineNo := '0' + TotalOrderLineNo;
                                                until StrLen(TotalOrderLineNo) = 3;
                                            end;

                                            OrderRequest += 'Z' + TotalOrderLineNo + '00002000000000040000' + OrderLineRequest;
                                        end;
                                        #endregion

                                        #Region Inserting Entry in Knapp Document Queue Table
                                        if OrderRequest <> '' then begin
                                            Clear(G_KnappDocumentQueue);
                                            G_KnappDocumentQueue.Reset();
                                            G_KnappDocumentQueue.Init();

                                            Rec_KnappDocumentQueue.Reset();
                                            Rec_KnappDocumentQueue.SetRange("Document Type", Rec_KnappDocumentQueue."Document Type"::Order);
                                            if Rec_KnappDocumentQueue.FindLast() then
                                                G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
                                            else
                                                G_KnappDocumentQueue."Entry No." := 1;

                                            G_KnappDocumentQueue."User ID" := UserId;
                                            G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::Order;
                                            G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
                                            G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
                                            G_KnappDocumentQueue.Request := CopyStr(OrderRequest, 1, 2048);
                                            G_KnappDocumentQueue."Document Reference No." := L_SalesHeader."No.";
                                            G_KnappDocumentQueue.Insert();
                                        end;
                                        #endregion
                                    end;

                                    Commit();
                                    NoOfOrders += 1;
                                    if NoOfOrders = OrderFilter."No. of Orders to Process" then begin
                                        Message('Process Completed');
                                        exit;
                                    end;
                                end;
                            end;
                        end;
                    until L_SalesLine.Next() = 0;
                end;
                Message('Process Completed');
            end;
        end;
    end;

    procedure GenerateOrdersNew()
    var
        OrderFilter: Record "Order Filter Table" temporary;
    begin
        #Region Creating a Temporary Entry for Filter Popup Page
        OrderFilter.DeleteAll();
        OrderFilter.Init();
        OrderFilter."Primary key" := 'KNAPP';
        OrderFilter."Shipment Date" := 0D;
        OrderFilter.Shift := OrderFilter.Shift::E;
        OrderFilter."No. of Orders to Process" := 0;
        OrderFilter.Insert();
        #endregion

        if Page.RunModal(90507, OrderFilter) = Action::LookupOK then begin
            if OrderFilter."Shipment Date" = 0D then
                Error('Please enter a valid Shipment Date');
            if OrderFilter.Shift = OrderFilter.Shift::" " then
                Error('Please choose a valid Shift');
            if (OrderFilter."No. of Orders to Process" = 0) and (OrderFilter."No. of Orders to Process" < 0) then
                Error('Please choose a valid number');
            if Confirm(StrSubstNo('You have selected Shipment Date "%1" and Shift "%2". Are you sure you want to continue?', OrderFilter."Shipment Date", OrderFilter.Shift)) then
                ProcessGenerateOrders(OrderFilter."Shipment Date", OrderFilter.Shift, OrderFilter."No. of Orders to Process");
        end;
    end;

    procedure GenerateOrdersAutomated()
    var
        OrderFilter: Record "Order Filter Table" temporary;
        ShipmentDate: Date;
        WeekDay: Integer;
    begin

        WeekDay := Date2DWY(WorkDate(), 1);

        case WeekDay of
            5: ////////////////Friday: +1D (Saturday) all shifts, +3D (Monday) A shift only
                begin
                    ShipmentDate := CalcDate('<+1D>', WorkDate());
                    ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::E, 0);
                    ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::A, 0);
                    ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::M, 0);
                    ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::X, 0);

                    ShipmentDate := CalcDate('<+3D>', WorkDate());
                    ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::A, 0);
                end;
            7: ///////////////////////////////////////////Sunday: +1D, all shifts except A
                begin
                    ShipmentDate := CalcDate('<+1D>', WorkDate());
                    ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::E, 0);
                    ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::M, 0);
                    ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::X, 0);
                end;
            else ////////////////////////All other days: current behavior - +1D, all shifts
                begin
                ShipmentDate := CalcDate('<+1D>', WorkDate());
                ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::E, 0);
                ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::A, 0);
                ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::M, 0);
                ProcessGenerateOrders(ShipmentDate, OrderFilter.Shift::X, 0);
            end;
        end;
    end;

    local procedure ProcessGenerateOrders(P_ShipmentDate: Date; P_Shift: Option E,A,M,X," "; P_NoOfOrdersToProcess: Integer)
    var
        L_SalesHeader: Record "Sales Header";
        L_SalesLine: Record "Sales Line";
        OrderLineRequest: Text;
        OrderArticleNumber: Text[20];
        L_Item: Record Item;
        TotalOrderLines: Integer;
        OrderLineQuantity: Text[4];
        OrderQuantity: Text;
        L_Customer: Record Customer;
        L_KnappStationNumbers: Record "Knapp Station Numbers";
        L_ShippingAgentServices: Record "Shipping Agent Services";
        CheckOrderDeleteExist: Boolean;
        NoOfOrders: Integer;
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
        Windows: Dialog;
    begin
        NoOfOrders := 0;
        if GuiAllowed then
            Windows.OPEN('Generating Orders..' + ' @1@@@@@@@@@@@@@\' + 'Please Wait..');
        NoOfRecs := P_NoOfOrdersToProcess;
        L_SalesHeader.Reset();
        L_SalesHeader.CalcFields("Sent to Knapp");
        L_SalesHeader.SetFilter("Document Type", '%1', L_SalesHeader."Document Type"::Order);
        L_SalesHeader.SetRange("Knapp Order", true);
        L_SalesHeader.SetRange("Sent to Knapp", false);
        L_SalesHeader.SetRange("Shipment Date", P_ShipmentDate);
        L_SalesHeader.SetFilter(Status, '%1', L_SalesHeader.Status::Released);
        if L_SalesHeader.FindSet() then begin
            repeat
                ClearOrderVariables();

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
                    if (L_ShippingAgentServices."Knapp Round" = true) and (Format(L_ShippingAgentServices.Shift) = Format(P_Shift)) then begin
                        ProgressCount += 1;
                        if GuiAllowed and (NoOfRecs > 0) then begin
                            if NoOfRecs <= 100 then begin
                                Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1)
                            end else begin
                                IF Count MOD (NoOfRecs DIV 100) = 0 THEN BEGIN
                                    Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1)
                                END;
                            end;
                        end;

                        OrderNumber := CopyStr(L_SalesHeader."No.", 1, 10);

                        CheckOrderExist := false;
                        CheckOrderExist := CheckOrderExistOrNot();

                        CheckOrderDeleteExist := false;
                        CheckOrderDeleteExist := CheckOrderDeleteExistOrNot();

                        if (CheckOrderExist = false) and (CheckOrderDeleteExist = false) then begin
                            #Region Data record identifier (In Document it is written only 6 Characters are allowed but actually 10 characters are allowed)
                            if StrLen(OrderNumber) < 10 then begin
                                repeat
                                    OrderNumber := ' ' + OrderNumber;
                                until StrLen(OrderNumber) = 10;
                            end;

                            OrderRequest := '12N1003' + OrderNumber + '000';
                            #endregion

                            #Region Order type identifier
                            OrderRequest += 'T0210';
                            #endregion

                            #Region Customer number identifier
                            OrderCustomerNo := CopyStr(L_SalesHeader."Sell-to Customer No.", 1, 12);
                            if StrLen(OrderCustomerNo) < 12 then begin
                                repeat
                                    OrderCustomerNo := ' ' + OrderCustomerNo;
                                until StrLen(OrderCustomerNo) = 12;
                            end;
                            OrderRequest += 'E12' + OrderCustomerNo;
                            #endregion

                            #Region Route number identifier
                            if L_SalesHeader."Weekend Ship. Agnt. Serv. Code" = '' then begin
                                OrderRouteNo := CopyStr(L_SalesHeader."Shipping Agent Service Code", 1, 8);
                            end
                            else begin
                                OrderRouteNo := CopyStr(L_SalesHeader."Weekend Ship. Agnt. Serv. Code", 1, 8);
                            end;

                            if StrLen(OrderRouteNo) < 8 then begin
                                repeat
                                    OrderRouteNo := ' ' + OrderRouteNo;
                                until StrLen(OrderRouteNo) = 8;
                            end;
                            OrderRequest += 'F08' + OrderRouteNo;
                            #endregion

                            #Region Drop Number
                            L_SalesHeader.CalcFields("Drop Number", "Weekend Drop Number");
                            if L_SalesHeader."Weekend Shipping Agent Code" <> '' then begin
                                if L_SalesHeader."Weekend Drop Number" = '0000' then
                                    OrderRequest += '00'
                                else
                                    OrderRequest += '04' + L_SalesHeader."Weekend Drop Number";
                            end else begin
                                if L_SalesHeader."Drop Number" = '0000' then
                                    OrderRequest += '00'
                                else
                                    OrderRequest += '04' + L_SalesHeader."Drop Number";
                            end;
                            #endregion

                            #Region target stations identifier
                            L_Customer.Reset();
                            L_Customer.SetRange("No.", L_SalesHeader."Sell-to Customer No.");
                            if L_Customer.FindFirst() then begin
                                if L_Customer."Knapp Special Check" = true then begin
                                    L_KnappStationNumbers.Reset();
                                    L_KnappStationNumbers.SetFilter("Special Check", '%1', true);
                                    if L_KnappStationNumbers.FindFirst() then begin
                                        TotalOrderStations += 1;
                                        OrderStationRequest := L_KnappStationNumbers."Station Number";
                                    end;
                                end;
                                if L_Customer."Knapp Final Check" = true then begin
                                    L_KnappStationNumbers.Reset();
                                    L_KnappStationNumbers.SetFilter("Final Check", '%1', true);
                                    if L_KnappStationNumbers.FindFirst() then begin
                                        TotalOrderStations += 1;
                                        if OrderStationRequest = '' then
                                            OrderStationRequest := L_KnappStationNumbers."Station Number"
                                        else begin
                                            OrderStationRequest += L_KnappStationNumbers."Station Number"
                                        end;
                                    end;
                                end;
                                if L_Customer."Knapp Invoice Station" = true then begin
                                    L_KnappStationNumbers.Reset();
                                    L_KnappStationNumbers.SetFilter("Invoice Station", '%1', true);
                                    if L_KnappStationNumbers.FindFirst() then begin
                                        TotalOrderStations += 1;
                                        if OrderStationRequest = '' then
                                            OrderStationRequest := L_KnappStationNumbers."Station Number"
                                        else begin
                                            OrderStationRequest += L_KnappStationNumbers."Station Number"
                                        end;
                                    end;
                                end;
                                if L_Customer."Knapp Repack" = true then begin
                                    L_KnappStationNumbers.Reset();
                                    L_KnappStationNumbers.SetFilter(Repacking, '%1', true);
                                    if L_KnappStationNumbers.FindFirst() then begin
                                        TotalOrderStations += 1;
                                        if OrderStationRequest = '' then
                                            OrderStationRequest := L_KnappStationNumbers."Station Number"
                                        else begin
                                            OrderStationRequest += L_KnappStationNumbers."Station Number"
                                        end;
                                    end;
                                end;
                                if L_Customer."Knapp Lid" = true then begin
                                    L_KnappStationNumbers.Reset();
                                    L_KnappStationNumbers.SetFilter(Lid, '%1', true);
                                    if L_KnappStationNumbers.FindFirst() then begin
                                        TotalOrderStations += 1;
                                        if OrderStationRequest = '' then
                                            OrderStationRequest := L_KnappStationNumbers."Station Number"
                                        else begin
                                            OrderStationRequest += L_KnappStationNumbers."Station Number"
                                        end;
                                    end;
                                end;

                                TotalStations := Format(TotalOrderStations);
                                if StrLen(TotalStations) < 2 then begin
                                    repeat
                                        TotalStations := '0' + TotalStations;
                                    until StrLen(TotalStations) = 2;
                                end;

                                OrderRequest += 'K' + TotalStations + '03' + OrderStationRequest;
                            end;
                            #endregion

                            #Region Order line identifier
                            Clear(OrderLineRequest);
                            TotalOrderLines := 0;
                            L_SalesLine.Reset();
                            L_SalesLine.SetFilter("Document Type", '%1', L_SalesLine."Document Type"::Order);
                            L_SalesLine.SetFilter(Type, '%1', L_SalesLine.Type::Item);
                            L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                            L_SalesLine.SetRange("Sent to Knapp", false);
                            L_SalesLine.SetRange("Knapp Line", true);
                            L_SalesLine.SetFilter(Quantity, '>%1', 0);
                            if L_SalesLine.FindSet() then begin
                                repeat
                                    Clear(OrderArticleNumber);
                                    Clear(OrderLineQuantity);
                                    Clear(OrderQuantity);
                                    Clear(L_Item);
                                    L_Item.Reset();
                                    L_Item.SetRange("No.", L_SalesLine."No.");
                                    if L_Item.FindFirst() then begin
                                        if L_Item."Knapp Item" = true then begin
                                            if L_SalesLine."Variant Code" <> '' then
                                                OrderArticleNumber := L_SalesLine."Variant Code"
                                            else
                                                OrderArticleNumber := CopyStr(L_Item."No.", 1, 20);
                                            if StrLen(OrderArticleNumber) < 20 then begin
                                                repeat
                                                    OrderArticleNumber := ' ' + OrderArticleNumber;
                                                until StrLen(OrderArticleNumber) = 20;
                                            end;

                                            OrderQuantity := Format(L_SalesLine.Quantity);
                                            if OrderQuantity.Contains(',') then
                                                OrderQuantity := OrderQuantity.Replace(',', '');
                                            OrderLineQuantity := CopyStr(OrderQuantity, 1, 4);
                                            if StrLen(OrderLineQuantity) < 4 then begin
                                                repeat
                                                    OrderLineQuantity := '0' + OrderLineQuantity;
                                                until StrLen(OrderLineQuantity) = 4;
                                            end;

                                            OrderLineRequest += OrderArticleNumber + OrderLineQuantity;
                                            TotalOrderLines += 1;
                                            L_SalesLine."Sent to Knapp" := true;
                                            L_SalesLine.Remarks := '';
                                            L_SalesLine.Modify();
                                        end;
                                    end;
                                until L_SalesLine.Next() = 0;

                                TotalOrderLineNo := Format(TotalOrderLines);
                                if StrLen(TotalOrderLineNo) < 3 then begin
                                    repeat
                                        TotalOrderLineNo := '0' + TotalOrderLineNo;
                                    until StrLen(TotalOrderLineNo) = 3;
                                end;

                                OrderRequest += 'Z' + TotalOrderLineNo + '00002000000000040000' + OrderLineRequest;
                            end;
                            #endregion

                            #Region Inserting Entry in Knapp Document Queue Table
                            if OrderRequest <> '' then begin
                                Clear(G_KnappDocumentQueue);
                                G_KnappDocumentQueue.Reset();
                                G_KnappDocumentQueue.Init();

                                Rec_KnappDocumentQueue.Reset();
                                Rec_KnappDocumentQueue.SetRange("Document Type", Rec_KnappDocumentQueue."Document Type"::Order);
                                if Rec_KnappDocumentQueue.FindLast() then
                                    G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
                                else
                                    G_KnappDocumentQueue."Entry No." := 1;

                                G_KnappDocumentQueue."User ID" := UserId;
                                G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::Order;
                                G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
                                G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
                                G_KnappDocumentQueue.Request := CopyStr(OrderRequest, 1, 2048);
                                G_KnappDocumentQueue."Document Reference No." := L_SalesHeader."No.";
                                G_KnappDocumentQueue.Insert();
                            end;
                            #endregion
                        end;

                        Commit();
                        NoOfOrders += 1;
                        if (P_NoOfOrdersToProcess > 0) and (NoOfOrders = P_NoOfOrdersToProcess) then begin
                            if GuiAllowed then
                                Message('Process Completed');
                            exit;
                        end;
                    end;
                end;
            until L_SalesHeader.Next() = 0;
        end;
    end;

    local procedure CheckOrderExistOrNot(): Boolean
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetRange("Document Type", L_KnappDocumentQueue."Document Type"::Order);
        L_KnappDocumentQueue.SetRange("Document Reference No.", OrderNumber);
        L_KnappDocumentQueue.SetFilter(Status, '%1|%2', L_KnappDocumentQueue.Status::New, L_KnappDocumentQueue.Status::Completed);
        if L_KnappDocumentQueue.FindFirst() then begin
            exit(true);
        end;
    end;

    local procedure CheckOrderDeleteExistOrNot(): Boolean
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetRange("Document Type", L_KnappDocumentQueue."Document Type"::"Order Delete");
        L_KnappDocumentQueue.SetRange("Document Reference No.", OrderNumber);
        L_KnappDocumentQueue.SetRange(Status, L_KnappDocumentQueue.Status::New);
        if L_KnappDocumentQueue.FindFirst() then begin
            exit(true);
        end;
    end;

    [TryFunction]
    procedure SyncOrderResponses(var P_KnappDocumentQueue: Record "Knapp Document Queue")
    var
        L_OrderUpdateRequest: Text;
        OrderNumber: Text;
        L_SalesLine: Record "Sales Line";
        L_SalesHeader: Record "Sales Header";
        StartIndex: Integer;
        ItemQuantity: Decimal;
        OrderStatus: Integer;
        OrderLinesUpdated: Boolean;
        SheetNumber: Integer;
        LoadUnit: Code[8];
        NewOrderResponse: Text;
        GenericRequest: Text;
        LoadUnitStatus: Text;
        OrderStationNumber: Text;
        LoadUnitStatusIdentifier: Text;
        LoadUnitStatusCount: Integer;
        CharacterCount: Integer;
        L_Customer: Record Customer;
        ProductNo: Text;
        L_KnappOrderResponse: Record "Knapp Order Response";
        L_KnappPickingDetails: Record "Knapp Picking Details";
    begin
        OrderLinesUpdated := false;

        Clear(L_OrderUpdateRequest);
        L_OrderUpdateRequest := P_KnappDocumentQueue.Request;

        Clear(OrderNumber);
        OrderNumber := P_KnappDocumentQueue."Document Reference No.";

        if IsOrderContainItems(OrderNumber, L_OrderUpdateRequest) then begin
            L_SalesHeader.Reset();
            L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
            L_SalesHeader.SetRange("No.", OrderNumber);
            if L_SalesHeader.FindFirst() then begin
                Clear(LoadUnit);
                LoadUnit := L_OrderUpdateRequest.Substring(24, 8);
                //LoadUnit := L_OrderUpdateRequest.Substring(31, 8);
                LoadUnit := Format(LoadUnit).Trim();
                if StrLen(LoadUnit) < 8 then begin
                    repeat
                        LoadUnit := '0' + LoadUnit;
                    until StrLen(LoadUnit) = 8;
                end;

                //Evaluate(SheetNumber, L_OrderUpdateRequest.Substring(25, 3));
                Evaluate(SheetNumber, L_OrderUpdateRequest.Substring(18, 3));

                L_SalesLine.Reset();
                L_SalesLine.SetFilter("Document Type", '%1', L_SalesLine."Document Type"::Order);
                L_SalesLine.SetFilter("Document No.", '%1', OrderNumber);
                L_SalesLine.SetFilter(Type, '%1', L_SalesLine.Type::Item);
                L_SalesLine.SetRange("Knapp Line", true);
                L_SalesLine.SetRange("Sent to Knapp", true);
                L_SalesLine.SetRange("Quantity Shipped", 0);
                if L_SalesLine.FindSet(true) then begin
                    repeat
                        Clear(StartIndex);
                        Clear(ItemQuantity);
                        Clear(OrderStatus);
                        if L_SalesLine."Variant Code" = '' then begin
                            if L_OrderUpdateRequest.Contains(L_SalesLine."No.") then begin
                                repeat
                                    Clear(ProductNo);
                                    Clear(GenericRequest);
                                    if StartIndex <> 0 then
                                        GenericRequest := NewOrderResponse
                                    else
                                        GenericRequest := L_OrderUpdateRequest;

                                    StartIndex := GenericRequest.IndexOf(L_SalesLine."No.");
                                    if GenericRequest <> '' then begin
                                        ProductNo := GenericRequest.Substring(StartIndex, 20);
                                        ProductNo := ProductNo.Trim();
                                        if ProductNo = L_SalesLine."No." then begin
                                            Evaluate(OrderStatus, GenericRequest.Substring(StartIndex + 28, 2));
                                            if (OrderStatus = 30) or (OrderStatus = 51) or (OrderStatus = 52) then begin
                                                Evaluate(ItemQuantity, GenericRequest.Substring(StartIndex + 24, 4));

                                                // if ItemQuantity > 0 then begin
                                                //     if L_SalesLine."Qty. to Ship" + ItemQuantity <= L_SalesLine.Quantity then
                                                //         L_SalesLine.Validate("Qty. to Ship", L_SalesLine."Qty. to Ship" + ItemQuantity);
                                                // end;
                                                // L_SalesLine.Validate("Sheet Number", SheetNumber);
                                                // L_SalesLine.Validate("Load Unit", LoadUnit);
                                                // L_SalesLine.Modify(true);
                                                OrderLinesUpdated := true;

                                                //Code to Create Entry in Intermediate Table to maintain Seperate Sheet No, Load Unit(Tote No)
                                                CreateEntryInKnappOrderResponse(L_SalesLine, SheetNumber, LoadUnit, ItemQuantity, false);
                                            end;
                                        end;

                                        Clear(NewOrderResponse);
                                        NewOrderResponse := GenericRequest.Substring(StartIndex + 20, StrLen(GenericRequest) - (StartIndex + 20));
                                        Clear(StartIndex);
                                        StartIndex := NewOrderResponse.IndexOf(L_SalesLine."No.");
                                    end;
                                until StartIndex = 0;
                            end;
                        end
                        else begin
                            if L_OrderUpdateRequest.Contains(L_SalesLine."Variant Code") then begin
                                repeat
                                    Clear(GenericRequest);
                                    if StartIndex <> 0 then
                                        GenericRequest := NewOrderResponse
                                    else
                                        GenericRequest := L_OrderUpdateRequest;

                                    StartIndex := GenericRequest.IndexOf(L_SalesLine."Variant Code");
                                    Evaluate(OrderStatus, GenericRequest.Substring(StartIndex + 28, 2));
                                    if (OrderStatus = 30) or (OrderStatus = 51) or (OrderStatus = 52) then begin
                                        Evaluate(ItemQuantity, GenericRequest.Substring(StartIndex + 24, 4));

                                        // if ItemQuantity > 0 then begin
                                        //     if L_SalesLine."Qty. to Ship" + ItemQuantity <= L_SalesLine.Quantity then
                                        //         L_SalesLine.Validate("Qty. to Ship", L_SalesLine."Qty. to Ship" + ItemQuantity);
                                        // end;
                                        // L_SalesLine.Validate("Sheet Number", SheetNumber);
                                        // L_SalesLine.Validate("Load Unit", LoadUnit);
                                        // L_SalesLine.Modify(true);
                                        OrderLinesUpdated := true;

                                        //Code to Create Entry in Intermediate Table to maintain Seperate Sheet No, Load Unit(Tote No)
                                        CreateEntryInKnappOrderResponse(L_SalesLine, SheetNumber, LoadUnit, ItemQuantity, false);
                                    end;

                                    Clear(NewOrderResponse);
                                    NewOrderResponse := GenericRequest.Substring(StartIndex + 20, StrLen(GenericRequest) - (StartIndex + 20));
                                    Clear(StartIndex);
                                    StartIndex := NewOrderResponse.IndexOf(L_SalesLine."Variant Code");
                                until StartIndex = 0;
                            end;
                        end;
                    until L_SalesLine.Next() = 0;
                end;

                if OrderLinesUpdated = true then begin
                    P_KnappDocumentQueue.Status := P_KnappDocumentQueue.Status::Completed;
                    P_KnappDocumentQueue."Updated Date/Time" := CurrentDateTime();
                    P_KnappDocumentQueue.Modify();

                    Clear(OrderStationNumber);
                    Clear(LoadUnitStatusIdentifier);
                    Clear(LoadUnitStatusCount);
                    Clear(CharacterCount);
                    Clear(LoadUnitStatus);
                    //if StrLen(P_KnappDocumentQueue.Request) > 61 then begin
                    if StrLen(P_KnappDocumentQueue.Request) > 54 then begin
                        //OrderStationNumber := P_KnappDocumentQueue.Request.Substring(61, 3);
                        OrderStationNumber := P_KnappDocumentQueue.Request.Substring(54, 3);

                        if (OrderStationNumber = '154') or (OrderStationNumber = '082') then begin
                            //if (StrLen(P_KnappDocumentQueue.Request) > 71) then begin
                            if (StrLen(P_KnappDocumentQueue.Request) > 64) then begin
                                //LoadUnitStatusIdentifier := P_KnappDocumentQueue.Request.Substring(71, 1);
                                LoadUnitStatusIdentifier := P_KnappDocumentQueue.Request.Substring(64, 1);
                                if LoadUnitStatusIdentifier = 'O' then begin
                                    //Evaluate(LoadUnitStatusCount, P_KnappDocumentQueue.Request.Substring(72, 2));
                                    Evaluate(LoadUnitStatusCount, P_KnappDocumentQueue.Request.Substring(65, 2));
                                    CharacterCount := ((LoadUnitStatusCount - 1) * 4) + 2;
                                    //LoadUnitStatus := P_KnappDocumentQueue.Request.Substring(74 + CharacterCount, 4);
                                    LoadUnitStatus := P_KnappDocumentQueue.Request.Substring(67 + CharacterCount, 4);

                                    if LoadUnitStatus = '0010' then begin
                                        L_Customer.Reset();
                                        if L_Customer.Get(L_SalesHeader."Sell-to Customer No.") then;
                                        if (L_SalesHeader."Sent Knapp Invoice" = false) and (L_Customer."Knapp Invoice Station" = true) then begin
                                            L_KnappOrderResponse.Reset();
                                            L_KnappOrderResponse.SetRange("Document Type", L_KnappOrderResponse."Document Type"::Order);
                                            L_KnappOrderResponse.SetRange("Document No.", L_SalesHeader."No.");
                                            L_KnappOrderResponse.SetFilter(Quantity, '>0');
                                            if L_KnappOrderResponse.FindFirst() then
                                                GenerateKnappInvoice(OrderNumber, L_SalesHeader);
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end
        else begin
            L_SalesHeader.Reset();
            L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
            L_SalesHeader.SetRange("No.", OrderNumber);
            if L_SalesHeader.FindFirst() then begin
                Clear(CharacterCount);
                CharacterCount := StrLen(P_KnappDocumentQueue.Request);
                if StrLen(P_KnappDocumentQueue.Request) = 30 then begin
                    if P_KnappDocumentQueue.Request.Substring(26, 4) = '0002' then begin
                        L_SalesHeader."Order Complete" := true;
                        L_SalesHeader.Modify();
                    end;
                end
                else begin
                    Clear(SheetNumber);
                    Evaluate(SheetNumber, L_OrderUpdateRequest.Substring(18, 3));

                    L_KnappPickingDetails.Reset();
                    L_KnappPickingDetails.SetRange("Document Type", L_KnappPickingDetails."Document Type"::Order);
                    L_KnappPickingDetails.SetRange("Document No.", OrderNumber);
                    L_KnappPickingDetails.SetRange("Sheet Number", SheetNumber);
                    if not L_KnappPickingDetails.FindFirst() then
                        CreateEntryInKnappPickingDetails(OrderNumber, SheetNumber);
                end;
                P_KnappDocumentQueue.Status := P_KnappDocumentQueue.Status::Completed;
                P_KnappDocumentQueue."Updated Date/Time" := CurrentDateTime();
                P_KnappDocumentQueue.Modify();
            end
            else begin
                P_KnappDocumentQueue.Status := P_KnappDocumentQueue.Status::Completed;
                P_KnappDocumentQueue."Updated Date/Time" := CurrentDateTime();
                P_KnappDocumentQueue.Modify();
            end;
        end;

        Commit();
    end;

    //Procedure to Check if Response Contains Order Products or not
    local procedure IsOrderContainItems(var P_OrderNumber: Text; var P_OrderRequest: Text): Boolean
    var
        L_SalesLine: Record "Sales Line";
        L_SalesHeader: Record "Sales Header";
        IsProductAvailable: Boolean;
        ProductNo: Text;
        StartIndex: Integer;
        GenericRequest: Text;
        NewOrderResponse: Text;
    begin
        IsProductAvailable := false;
        L_SalesHeader.Reset();
        L_SalesHeader.SetRange("No.", P_OrderNumber);
        if L_SalesHeader.FindFirst() then begin
            L_SalesLine.Reset();
            L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type");
            L_SalesLine.SetRange("Document No.", P_OrderNumber);
            L_SalesLine.SetFilter(Type, '%1', L_SalesLine.Type::Item);
            L_SalesLine.SetRange("Knapp Line", true);
            L_SalesLine.SetRange("Sent to Knapp", true);
            L_SalesLine.SetRange("Quantity Shipped", 0);
            if L_SalesLine.FindSet() then begin
                repeat
                    if L_SalesLine."Variant Code" = '' then begin
                        if P_OrderRequest.Contains(L_SalesLine."No.") then begin
                            Clear(StartIndex);
                            repeat
                                Clear(ProductNo);
                                Clear(GenericRequest);
                                if StartIndex <> 0 then
                                    GenericRequest := NewOrderResponse
                                else
                                    GenericRequest := P_OrderRequest;

                                StartIndex := GenericRequest.IndexOf(L_SalesLine."No.");
                                if GenericRequest <> '' then begin
                                    ProductNo := GenericRequest.Substring(StartIndex, 20);
                                    ProductNo := ProductNo.Trim();
                                    if ProductNo = L_SalesLine."No." then begin
                                        IsProductAvailable := true;
                                    end;

                                    Clear(NewOrderResponse);
                                    NewOrderResponse := GenericRequest.Substring(StartIndex + 20, StrLen(GenericRequest) - (StartIndex + 20));
                                    Clear(StartIndex);
                                    StartIndex := NewOrderResponse.IndexOf(L_SalesLine."No.");
                                end;
                            until StartIndex = 0;
                        end;
                    end
                    else begin
                        if P_OrderRequest.Contains(L_SalesLine."Variant Code") then begin
                            IsProductAvailable := true;
                        end;
                    end;

                    if IsProductAvailable = true then
                        break;
                until L_SalesLine.Next() = 0;
            end;
        end;
        exit(IsProductAvailable);
    end;

    local procedure CreateEntryInKnappOrderResponse(var P_SalesLine: Record "Sales Line"; P_SheetNo: Integer; P_LoadUnit: Code[8]; ItemQuantity: Decimal; ManualPick: Boolean)
    var
        L_KnappOrderResponse: Record "Knapp Order Response";
        Rec_KnappOrderResponse: Record "Knapp Order Response";
    begin
        Clear(L_KnappOrderResponse);
        L_KnappOrderResponse.Reset();
        L_KnappOrderResponse.Init();

        Rec_KnappOrderResponse.Reset();
        if Rec_KnappOrderResponse.FindLast() then
            L_KnappOrderResponse."Entry No." := Rec_KnappOrderResponse."Entry No." + 1
        else
            L_KnappOrderResponse."Entry No." := 1;

        L_KnappOrderResponse."Document Type" := P_SalesLine."Document Type";
        L_KnappOrderResponse."Document No." := P_SalesLine."Document No.";
        L_KnappOrderResponse."Line No." := P_SalesLine."Line No.";
        L_KnappOrderResponse."Item No." := P_SalesLine."No.";
        L_KnappOrderResponse."Variant Code" := P_SalesLine."Variant Code";
        L_KnappOrderResponse.Description := P_SalesLine.Description;
        L_KnappOrderResponse."Unit of Measure" := P_SalesLine."Unit of Measure";
        L_KnappOrderResponse.Quantity := ItemQuantity;
        L_KnappOrderResponse."Unit Price" := P_SalesLine."Unit Price";
        L_KnappOrderResponse."Line Discount %" := P_SalesLine."Line Discount %";
        L_KnappOrderResponse.Amount := (ItemQuantity * P_SalesLine."Unit Price") - ((ItemQuantity * P_SalesLine."Unit Price" * P_SalesLine."Line Discount %") / 100);
        L_KnappOrderResponse."VAT Identifier" := P_SalesLine."VAT Identifier";
        L_KnappOrderResponse."VAT %" := P_SalesLine."VAT %";
        L_KnappOrderResponse."VAT Amount" := (ROUND((L_KnappOrderResponse.Amount * (P_SalesLine."VAT %" / 100)), 0.01, '='));
        L_KnappOrderResponse."Amount Including VAT" := L_KnappOrderResponse.Amount + L_KnappOrderResponse."VAT Amount";
        L_KnappOrderResponse."Sheet Number" := P_SheetNo;
        L_KnappOrderResponse."Load Unit" := P_LoadUnit;
        if ManualPick = false then
            L_KnappOrderResponse."From Knapp" := true;
        L_KnappOrderResponse.Insert();
    end;

    procedure GenerateKnappInvoice(P_OrderNumber: Text; var P_SalesHeader: Record "Sales Header")
    var
        RequestBody: Text;
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        ResponseText: Text;
        Response: Text;
        URL: Text;
        TempBlob: Codeunit "Temp Blob";
        InvoiceOutStream: OutStream;
        InvoiceInStream: InStream;
        CU_Base64: Codeunit "Base64 Convert";
        Base64Response: Text;
        L_KnappSalesInvoice: xmlport "Knapp Sales Invoice";
        L_SalesAndRecSetup: Record "Sales & Receivables Setup";
    begin
        Clear(Headers);
        Clear(Content);
        Clear(Client);
        Clear(RequestBody);
        Clear(URL);
        Clear(TempBlob);
        Clear(InvoiceOutStream);
        Clear(InvoiceInStream);
        Clear(Response);
        Clear(Base64Response);
        Clear(ResponseText);

        L_SalesAndRecSetup.Get();
        L_SalesAndRecSetup.TestField("eVo Upload Key");

        TempBlob.CreateOutStream(InvoiceOutStream);
        L_KnappSalesInvoice.SetTableView(P_SalesHeader);
        L_KnappSalesInvoice.SetDestination(InvoiceOutStream);
        L_KnappSalesInvoice.Export();
        TempBlob.CreateInStream(InvoiceInStream, TextEncoding::UTF8);
        InvoiceInStream.Read(Response);
        //Message(Response);
        Base64Response := CU_Base64.ToBase64(Response);
        //Message(Base64Response);

        RequestBody := StrSubstNo('{"filename": "KnappInvoice_%1.xml","uploadKey": "%2","content": "%3"}',
                                    P_OrderNumber, L_SalesAndRecSetup."eVo Upload Key", Base64Response);

        Content.WriteFrom(RequestBody);
        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Accept', 'application/json');
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        URL := 'http://31.121.152.186:1020/file/bodyupload';

        if Client.Post(URL, Content, ResponseMessage) then begin
            ResponseMessage.Content.ReadAs(ResponseText);
            //Message(ResponseText);
            if ResponseMessage.HttpStatusCode = 200 then begin
                P_SalesHeader."Sent Knapp Invoice" := true;
            end;

            P_SalesHeader."Knapp Invoice Remark" := CopyStr(ResponseText, 1, 2048);
            P_SalesHeader.Modify();
        end;
    end;

    local procedure CreateEntryInKnappPickingDetails(P_OrderNumber: Text; P_SheetNo: Integer)
    var
        L_KnappPickingDetails: Record "Knapp Picking Details";
        Rec_KnappPickingDetails: Record "Knapp Picking Details";
    begin
        Clear(L_KnappPickingDetails);
        L_KnappPickingDetails.Reset();
        L_KnappPickingDetails.Init();

        Rec_KnappPickingDetails.Reset();
        if Rec_KnappPickingDetails.FindLast() then
            L_KnappPickingDetails."Entry No." := Rec_KnappPickingDetails."Entry No." + 1
        else
            L_KnappPickingDetails."Entry No." := 1;

        L_KnappPickingDetails."Document Type" := L_KnappPickingDetails."Document Type"::Order;
        L_KnappPickingDetails."Document No." := P_OrderNumber;
        L_KnappPickingDetails."Sheet Number" := P_SheetNo;
        L_KnappPickingDetails.Insert();
    end;

    procedure GenerateDeleteOrderRequest(var P_KnappDocumentQueue: Record "Knapp Document Queue")
    var
        OrderDeleteRequest: Text;
    begin
        #Region Order Delete Request Generation
        Clear(OrderDeleteRequest);
        Clear(OrderNumber);
        OrderNumber := P_KnappDocumentQueue."Document Reference No.";
        if StrLen(OrderNumber) < 10 then begin
            repeat
                OrderNumber := ' ' + OrderNumber;
            until StrLen(OrderNumber) = 10;
        end;
        OrderDeleteRequest := '12D1003' + OrderNumber + '000';
        #endregion

        #Region Inserting Order Delete Entry in Knapp Document Queue
        Clear(G_KnappDocumentQueue);
        G_KnappDocumentQueue.Reset();
        G_KnappDocumentQueue.Init();

        Rec_KnappDocumentQueue.Reset();
        Rec_KnappDocumentQueue.SetRange("Document Type", Rec_KnappDocumentQueue."Document Type"::"Order Delete");
        if Rec_KnappDocumentQueue.FindLast() then
            G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
        else
            G_KnappDocumentQueue."Entry No." := 1;

        G_KnappDocumentQueue."User ID" := UserId;
        G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Order Delete";
        G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
        G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
        G_KnappDocumentQueue.Request := CopyStr(OrderDeleteRequest, 1, 2048);
        G_KnappDocumentQueue."Document Reference No." := P_KnappDocumentQueue."Document Reference No.";
        G_KnappDocumentQueue.Insert();
        #endregion
    end;

    procedure GenerateKnappDeleteOrderRequest(var P_KnappDocumentQueue: Record "Knapp Document Queue")
    var
        OrderResponseExist: Boolean;
        OrderDeleteRequest: Text;
        OrderReOpened: Boolean;
        L_SalesHeader: Record "Sales Header";
        L_SalesLine: Record "Sales Line";
        CU_ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        OrderResponseExist := false;
        OrderResponseExist := CheckOrderResponseExist(P_KnappDocumentQueue);

        if OrderResponseExist = false then begin
            #Region Order Delete Request Generation
            Clear(OrderDeleteRequest);
            Clear(OrderNumber);
            OrderNumber := P_KnappDocumentQueue."Document Reference No.";
            if StrLen(OrderNumber) < 10 then begin
                repeat
                    OrderNumber := ' ' + OrderNumber;
                until StrLen(OrderNumber) = 10;
            end;
            OrderDeleteRequest := '12D1003' + OrderNumber + '000';
            #endregion

            #Region Inserting Order Delete Entry in Knapp Document Queue
            Clear(G_KnappDocumentQueue);
            G_KnappDocumentQueue.Reset();
            G_KnappDocumentQueue.Init();

            Rec_KnappDocumentQueue.Reset();
            Rec_KnappDocumentQueue.SetRange("Document Type", Rec_KnappDocumentQueue."Document Type"::"Order Delete");
            if Rec_KnappDocumentQueue.FindLast() then
                G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
            else
                G_KnappDocumentQueue."Entry No." := 1;

            G_KnappDocumentQueue."User ID" := UserId;
            G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Order Delete";
            G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
            G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
            G_KnappDocumentQueue.Request := CopyStr(OrderDeleteRequest, 1, 2048);
            G_KnappDocumentQueue."Document Reference No." := P_KnappDocumentQueue."Document Reference No.";
            G_KnappDocumentQueue.Insert();
            #endregion

            OrderReOpened := false;
            L_SalesHeader.Reset();
            L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
            L_SalesHeader.SetRange("No.", P_KnappDocumentQueue."Document Reference No.");
            if L_SalesHeader.FindFirst() then begin
                if L_SalesHeader.Status = L_SalesHeader.Status::Released then begin
                    CU_ReleaseSalesDoc.PerformManualReopen(L_SalesHeader);
                    OrderReOpened := true;
                end;

                L_SalesLine.Reset();
                L_SalesLine.SetFilter("Document Type", '%1', L_SalesLine."Document Type"::Order);
                L_SalesLine.SetFilter(Type, '%1', L_SalesLine.Type::Item);
                L_SalesLine.SetFilter("Document No.", L_SalesHeader."No.");
                L_SalesLine.SetRange("Knapp Line", true);
                L_SalesLine.SetRange("Sent to Knapp", true);
                if L_SalesLine.FindSet() then begin
                    repeat
                        L_SalesLine."Sent to Knapp" := false;
                        L_SalesLine.Validate("Qty. to Ship", 0);
                        L_SalesLine."Sheet Number" := 0;
                        L_SalesLine."Load Unit" := '';
                        L_SalesLine.Remarks := '';
                        L_SalesLine.Modify(true);
                    until L_SalesLine.Next() = 0;
                end;

                if OrderReOpened = true then
                    CU_ReleaseSalesDoc.PerformManualRelease(L_SalesHeader);
            end;

            P_KnappDocumentQueue.Delete();
            Commit();
        end;
    end;

    procedure CheckOrderResponseExist(var P_KnappDocumentQueue: Record "Knapp Document Queue"): Boolean
    var
        L_KnappOrderResponse: Record "Knapp Order Response";
        L_KnappDocumentQueue: Record "Knapp Document Queue";
    begin
        L_KnappOrderResponse.Reset();
        L_KnappOrderResponse.SetRange("Document Type", L_KnappOrderResponse."Document Type"::Order);
        L_KnappOrderResponse.SetRange("Document No.", P_KnappDocumentQueue."Document Reference No.");
        if L_KnappOrderResponse.FindFirst() then
            exit(true);

        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetRange("Document Type", L_KnappDocumentQueue."Document Type"::"Order Update");
        L_KnappDocumentQueue.SetRange("Document Reference No.", P_KnappDocumentQueue."Document Reference No.");
        if L_KnappDocumentQueue.FindFirst() then
            exit(true);
    end;

    procedure ConvertKnappToNonKnapp(var P_KnappDocumentQueue: Record "Knapp Document Queue")
    var
        L_SalesHeader: Record "Sales Header";
        L_SalesLine: Record "Sales Line";
        LineUpdated: Boolean;
        OrderReOpened: Boolean;
        CU_ReleaseSalesDoc: Codeunit "Release Sales Document";
        L_Location: Record Location;
    begin
        LineUpdated := false;
        OrderReOpened := false;

        L_Location.Reset();
        L_Location.SetRange("Saleable Location", true);
        L_Location.SetRange("Knapp Location", false);
        if L_Location.FindFirst() then;

        L_SalesHeader.Reset();
        L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
        L_SalesHeader.SetRange("No.", P_KnappDocumentQueue."Document Reference No.");
        if L_SalesHeader.FindFirst() then begin
            if L_SalesHeader.Status = L_SalesHeader.Status::Released then begin
                CU_ReleaseSalesDoc.PerformManualReopen(L_SalesHeader);
                OrderReOpened := true;
            end;

            L_SalesLine.Reset();
            L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type");
            L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
            if L_SalesLine.FindSet() then begin
                repeat
                    L_SalesLine."Knapp Line" := false;
                    L_SalesLine."Sent to Knapp" := false;
                    L_SalesLine.Validate("Qty. to Ship", L_SalesLine.Quantity);
                    L_SalesLine.Validate("Qty. to Invoice", L_SalesLine.Quantity);
                    L_SalesLine."Location Code" := L_Location.Code;
                    L_SalesLine.Modify(true);
                    LineUpdated := true;
                until L_SalesLine.Next() = 0;
            end;

            if LineUpdated = true then begin
                L_SalesHeader."Knapp Order" := false;
                L_SalesHeader."Posting No." := '';
                L_SalesHeader."Location Code" := L_Location.Code;
                L_SalesHeader.Modify();

                P_KnappDocumentQueue."Converted to Non-Knapp" := true;
                P_KnappDocumentQueue.Modify();
            end;

            if OrderReOpened = true then
                CU_ReleaseSalesDoc.PerformManualRelease(L_SalesHeader);

            Commit();
        end;
    end;

    procedure KnappManualResponse(var P_SalesHeader: Record "Sales Header")
    var
        OrderFilter: Record "Order Filter Table";
        ToteNumber: Code[8];
        SheetNumber: Integer;
        L_KnappOrderResponse: Record "Knapp Order Response";
        L_SalesLine: Record "Sales Line";
        ItemQuantity: Decimal;
        EntryInserted: Boolean;
        L_KnappPickingDetails: Record "Knapp Picking Details";
    begin
        #Region Creating a Temporary Entry for Filter Popup Page
        OrderFilter.DeleteAll();
        OrderFilter.Init();
        OrderFilter."Primary key" := P_SalesHeader."No.";
        Clear(OrderFilter."Tote Number");

        L_KnappPickingDetails.Reset();
        L_KnappPickingDetails.CalcFields("Knapp Response Exist");
        L_KnappPickingDetails.SetRange("Document Type", L_KnappPickingDetails."Document Type"::Order);
        L_KnappPickingDetails.SetRange("Document No.", P_SalesHeader."No.");
        L_KnappPickingDetails.SetRange("Knapp Response Exist", false);
        if L_KnappPickingDetails.FindFirst() then
            OrderFilter.Validate("Sheet Number", L_KnappPickingDetails."Sheet Number");

        OrderFilter.Insert();
        Commit();
        #endregion

        if Page.RunModal(90512, OrderFilter) = Action::LookupOK then begin
            if OrderFilter."Tote Number" = '' then
                Error('Please enter a valid Tote Number');
            if OrderFilter."Sheet Number" = 0 then
                Error('Please choose a valid Sheet Number');
            if Confirm(StrSubstNo('You have selected Tote Number "%1" and Sheet Number "%2". Are you sure you want to continue?', OrderFilter."Tote Number", OrderFilter."Sheet Number")) then begin
                Clear(ToteNumber);
                Clear(SheetNumber);
                ToteNumber := Format(OrderFilter."Tote Number");
                SheetNumber := OrderFilter."Sheet Number";

                EntryInserted := false;
                L_SalesLine.Reset();
                L_SalesLine.SetRange("Document Type", P_SalesHeader."Document Type");
                L_SalesLine.SetRange("Document No.", P_SalesHeader."No.");
                L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                L_SalesLine.SetRange("Knapp Line", true);
                L_SalesLine.SetRange("Sent to Knapp", true);
                if L_SalesLine.FindSet() then begin
                    repeat
                        Clear(ItemQuantity);
                        L_SalesLine.CalcFields("Knapp Qty. to Ship");
                        //if L_SalesLine.Quantity <> L_SalesLine."Knapp Qty. to Ship" then begin
                        L_KnappOrderResponse.Reset();
                        L_KnappOrderResponse.SetRange("Document Type", L_KnappOrderResponse."Document Type"::Order);
                        L_KnappOrderResponse.SetRange("Document No.", L_SalesLine."Document No.");
                        L_KnappOrderResponse.SetRange("Line No.", L_SalesLine."Line No.");
                        L_KnappOrderResponse.SetRange("Item No.", L_SalesLine."No.");
                        L_KnappOrderResponse.SetRange("Load Unit", ToteNumber);
                        L_KnappOrderResponse.SetRange("Sheet Number", SheetNumber);
                        if not L_KnappOrderResponse.FindFirst() then begin
                            ItemQuantity := L_SalesLine.Quantity - L_SalesLine."Knapp Qty. to Ship";
                            CreateEntryInKnappOrderResponse(L_SalesLine, SheetNumber, ToteNumber, ItemQuantity, true);
                            EntryInserted := true;
                        end;
                    // else begin
                    //     if L_SalesLine.Quantity - L_SalesLine."Knapp Qty. to Ship" = 0 then begin
                    //         CreateEntryInKnappOrderResponse(L_SalesLine, SheetNumber, ToteNumber, 0, true);
                    //         EntryInserted := true;
                    //     end;

                    //end;
                    //end;
                    until L_SalesLine.Next() = 0;
                end;

                if (EntryInserted = true) and (P_SalesHeader."Order Complete" = true) then begin
                    L_KnappPickingDetails.Reset();
                    L_KnappPickingDetails.SetRange("Document Type", L_KnappPickingDetails."Document Type"::Order);
                    L_KnappPickingDetails.SetRange("Document No.", P_SalesHeader."No.");
                    L_KnappPickingDetails.SetRange("Sheet Number", SheetNumber);
                    if L_KnappPickingDetails.FindFirst() then begin
                        L_KnappPickingDetails."Tote Number" := ToteNumber;
                        L_KnappPickingDetails.Modify();
                    end;

                    P_SalesHeader."Order Complete" := false;
                    P_SalesHeader.Modify();
                end;

                Message('Process Completed');
                Commit();
            end;
        end;
    end;

    local procedure MoveKnappDocumentsToArchive()
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
        L_ArchiveKnappDocumentQueue: Record "Archive Knapp Document Queue";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter(Status, '%1', L_KnappDocumentQueue.Status::Completed);
        L_KnappDocumentQueue.SetFilter("Created Date/Time", '<%1', CreateDateTime(CalcDate('-2W', Today()), DT2Time(CurrentDateTime)));
        if L_KnappDocumentQueue.FindSet() then begin
            repeat
                L_ArchiveKnappDocumentQueue.Init();
                L_ArchiveKnappDocumentQueue.TransferFields(L_KnappDocumentQueue);
                L_ArchiveKnappDocumentQueue.Insert();

                L_KnappDocumentQueue."Moved to Archive" := true;
                L_KnappDocumentQueue.Modify();
                Commit();
            until L_KnappDocumentQueue.Next() = 0;
        end;

        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter(Status, '%1', L_KnappDocumentQueue.Status::Completed);
        L_KnappDocumentQueue.SetRange("Moved to Archive", true);
        if L_KnappDocumentQueue.FindSet() then
            L_KnappDocumentQueue.DeleteAll();
    end;

    #Region Initial Master Sync Procedures
    procedure DeleteArticleMasters()
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
        L_ItemReference: Record "Item Reference";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter("Document Type", '%1|%2|%3', L_KnappDocumentQueue."Document Type"::"Article Master", L_KnappDocumentQueue."Document Type"::"Article Update", L_KnappDocumentQueue."Document Type"::"Article Delete");
        if L_KnappDocumentQueue.FindSet() then begin
            L_KnappDocumentQueue.DeleteAll();
        end;

        L_ItemReference.Reset();
        L_ItemReference.SetRange("Reference Type", L_ItemReference."Reference Type"::"Article Number");
        L_ItemReference.SetRange("Sent to Knapp", true);
        if L_ItemReference.FindSet() then begin
            L_ItemReference.ModifyAll("Sent to Knapp", false);
        end;

        Commit();
    end;

    procedure GenerateInitialArticleMaster()
    var
        L_Item: Record Item;
        L_ItemReference: Record "Item Reference";
        L_KnappStationNo: Record "Knapp Station Numbers";
        L_KnappItemDetails: Record "Knapp Item Details";
        L_KnappItemDimensions: Record "Knapp Item Dimensions";
        DocumentReference: Text;
        IsArticleExist: Boolean;
        EntryInserted: Boolean;
        L_ItemVariant: Record "Item Variant";
        IsItemVariantMandatory: Boolean;
        Windows: Dialog;
    begin
        Windows.OPEN('Generating Article Master..' + ' @1@@@@@@@@@@@@@\' + 'Generating..' + ' #3##########' + 'Please Wait..');
        L_ItemReference.Reset();
        L_ItemReference.SetRange(Knapp, true);
        L_ItemReference.SetRange("Sent to Knapp", false);
        L_ItemReference.SetFilter("Item No.", '<>%1', '');
        L_ItemReference.SetFilter("Reference Type", '%1', L_ItemReference."Reference Type"::"Article Number");
        if L_ItemReference.FindSet() then begin
            repeat
                NoOfRecs := L_ItemReference.Count;

                IsItemVariantMandatory := false;
                L_Item.Reset();
                if L_Item.Get(L_ItemReference."Item No.") then begin
                    L_Item.CalcFields("Variant Exist");
                    if L_Item."Variant Exist" = true then begin
                        if L_ItemReference."Variant Code" <> '' then
                            IsItemVariantMandatory := true;
                    end
                    else begin
                        IsItemVariantMandatory := true;
                    end;
                end;

                if IsItemVariantMandatory = true then begin
                    ProgressCount += 1;
                    IF NoOfRecs <= 100 THEN
                        Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1)
                    ELSE
                        IF Count MOD (NoOfRecs DIV 100) = 0 THEN BEGIN
                            Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1)
                        END;
                    Windows.UPDATE(3, L_ItemReference."Item No.");

                    EntryInserted := false;
                    L_KnappItemDetails.Reset();
                    L_KnappItemDetails.SetRange("Item No.", L_ItemReference."Item No.");
                    L_KnappItemDetails.SetRange("Item Reference No.", L_ItemReference."Reference No.");
                    L_KnappItemDetails.SetRange("Item Reference Type", L_ItemReference."Reference Type");
                    if L_ItemReference."Variant Code" <> '' then
                        L_KnappItemDetails.SetRange("Item Variant Code", L_ItemReference."Variant Code");
                    if L_KnappItemDetails.FindSet() then begin
                        repeat
                            L_KnappItemDimensions.Reset();
                            L_KnappItemDimensions.SetRange("Item No.", L_ItemReference."Item No.");
                            L_KnappItemDimensions.SetRange("Item Reference No.", L_ItemReference."Reference No.");
                            L_KnappItemDimensions.SetRange("Item Reference Type", L_ItemReference."Reference Type");
                            L_KnappItemDimensions.SetFilter("Pack Size", '%1', L_KnappItemDetails."Knapp Pack Size");
                            if L_ItemReference."Variant Code" <> '' then
                                L_KnappItemDimensions.SetRange("Item Variant Code", L_ItemReference."Variant Code");
                            if L_KnappItemDimensions.FindFirst() then begin
                                ClearArticleMasterVariables();

                                #Region Getting Data for Knapp Article
                                StationNo := L_KnappItemDetails."Knapp Station Number";
                                Aisle := Format(L_KnappItemDetails."Knapp Aisle");
                                Rack := Format(L_KnappItemDetails."Knapp Rack");
                                RackLevel := Format(L_KnappItemDetails."Knapp Rack Level");
                                Position := Format(L_KnappItemDetails."Knapp Position");
                                ArticleCode := CopyStr(L_ItemReference."Reference No.", 1, 14);
                                PackSize := Format(L_KnappItemDetails."Knapp Pack Size");
                                Length := Format(L_KnappItemDimensions.Length, 4);
                                Width := Format(L_KnappItemDimensions.Width, 4);
                                Height := Format(L_KnappItemDimensions.Height, 4);
                                Weight := Format(L_KnappItemDimensions.Weight, 6, '<Integer>');
                                StorageLocation := L_KnappItemDetails."Knapp Storage Location";
                                EjectionNo := L_KnappItemDetails."Knapp Ejection No";
                                MaximumQty := Format(L_KnappItemDetails."Maximum ACS Quantity", 4, '<Integer>');
                                MaximumStock := Format(L_KnappItemDetails."Knapp Maximum Stock", 4, '<Integer>');
                                MinimumStock := Format(L_KnappItemDetails."Knapp Minimum Stock", 4, '<Integer>');
                                OverstockStorageLocation := L_KnappItemDetails."Overstock Storage Location";
                                if L_ItemReference."Variant Code" <> '' then
                                    ArticleNo := L_ItemReference."Variant Code"
                                else
                                    ArticleNo := L_ItemReference."Item No.";

                                L_KnappStationNo.Reset();
                                L_KnappStationNo.SetRange("Station Number", StationNo);
                                if L_KnappStationNo.FindFirst() then begin
                                    ArticleType := Format(L_KnappStationNo.Type);
                                end;

                                ArticleName := CopyStr(L_ItemReference."Description 2", 1, 40);
                                if ArticleName = '' then begin
                                    if L_ItemReference."Variant Code" <> '' then begin
                                        Clear(L_ItemVariant);
                                        L_ItemVariant.Reset();
                                        L_ItemVariant.SetRange("Item No.", L_ItemReference."Item No.");
                                        L_ItemVariant.SetRange(Code, L_ItemReference."Variant Code");
                                        if L_ItemVariant.FindFirst() then begin
                                            ArticleName := CopyStr(L_ItemVariant.Description, 1, 40);
                                        end;
                                    end;

                                    Clear(L_Item);
                                    L_Item.Reset();
                                    L_Item.SetRange("No.", L_ItemReference."Item No.");
                                    if L_Item.FindFirst() then begin
                                        ArticleName := CopyStr(L_Item.Description, 1, 40);
                                        //MaximumQty := Format(L_Item."Knapp Threshold Quantity");
                                    end;
                                end;
                                #endregion

                                #Region Data Record Identifier
                                if StrLen(StationNo) < 3 then begin
                                    repeat
                                        StationNo := '0' + StationNo;
                                    until StrLen(StationNo) = 3;
                                end;

                                if StrLen(Aisle) < 3 then begin
                                    repeat
                                        Aisle := '0' + Aisle;
                                    until StrLen(Aisle) = 3;
                                end;

                                if StrLen(Rack) < 3 then begin
                                    repeat
                                        Rack := '0' + Rack;
                                    until StrLen(Rack) = 3;
                                end;

                                if StrLen(RackLevel) < 3 then begin
                                    repeat
                                        RackLevel := '0' + RackLevel;
                                    until StrLen(RackLevel) = 3;
                                end;

                                if StrLen(Position) < 3 then begin
                                    repeat
                                        Position := '0' + Position;
                                    until StrLen(Position) = 3;
                                end;

                                if ArticleType = 'Manual Station' then begin
                                    ArticleRequest := '14N030303030300' + StationNo + Aisle + Rack + RackLevel + Position;
                                end
                                else begin
                                    ArticleRequest := '14N030003030300' + StationNo + Rack + RackLevel + Position;
                                end;
                                #endregion

                                #Region Article number / pack size identifier
                                if StrLen(ArticleNo) < 20 then begin
                                    repeat
                                        ArticleNo := ' ' + ArticleNo;
                                    until StrLen(ArticleNo) = 20;
                                end;

                                if StrLen(PackSize) < 4 then begin
                                    repeat
                                        PackSize := '0' + PackSize;
                                    until StrLen(PackSize) = 4;
                                end;

                                ArticleRequest += 'L2004' + ArticleNo + PackSize;
                                #endregion

                                #Region Ejection number identifier
                                if StrLen(EjectionNo) < 2 then begin
                                    repeat
                                        EjectionNo := '0' + EjectionNo;
                                    until StrLen(EjectionNo) = 2;
                                end;
                                if ArticleType <> 'Manual Station' then begin
                                    ArticleRequest += 'Y02' + EjectionNo;
                                end;
                                #endregion

                                #Region Maximum quantity identifier
                                if MaximumQty.Contains(',') then
                                    MaximumQty := MaximumQty.Replace(',', '');
                                if StrLen(MaximumQty) < 4 then begin
                                    repeat
                                        MaximumQty := '0' + MaximumQty;
                                    until StrLen(MaximumQty) = 4;
                                end;
                                if ArticleType <> 'Manual Station' then begin
                                    ArticleRequest += 'M04' + MaximumQty;
                                end;
                                #endregion

                                #Region Dimensions identifier
                                if StrLen(Length) < 4 then begin
                                    repeat
                                        Length := '0' + Length;
                                    until StrLen(Length) = 4;
                                end;

                                if StrLen(Width) < 4 then begin
                                    repeat
                                        Width := '0' + Width;
                                    until StrLen(Width) = 4;
                                end;

                                if StrLen(Height) < 4 then begin
                                    repeat
                                        Height := '0' + Height;
                                    until StrLen(Height) = 4;
                                end;

                                ArticleRequest += 'D040404' + Length + Width + Height;
                                #endregion

                                #Region Weight identifier
                                if StrLen(Weight) < 6 then begin
                                    repeat
                                        Weight := '0' + Weight;
                                    until StrLen(Weight) = 6;
                                end;

                                ArticleRequest += 'G06' + Weight;
                                #endregion

                                #Region Article code identifier
                                if StrLen(ArticleCode) < 14 then begin
                                    repeat
                                        ArticleCode += ' ';
                                    until StrLen(ArticleCode) = 14;
                                end;

                                ArticleRequest += 'B0114' + ArticleCode;
                                #endregion

                                #Region Article name identifier
                                if StrLen(ArticleName) < 40 then begin
                                    repeat
                                        ArticleName := ' ' + ArticleName;
                                    until StrLen(ArticleName) = 40;
                                end;

                                if StrLen(StorageLocation) < 12 then begin
                                    repeat
                                        StorageLocation := ' ' + StorageLocation;
                                    until StrLen(StorageLocation) = 12;
                                end;

                                ArticleRequest += 'K4012' + ArticleName + StorageLocation;
                                #endregion

                                #Region Stock limits identifier
                                if StrLen(MinimumStock) < 4 then begin
                                    repeat
                                        MinimumStock := '0' + MinimumStock;
                                    until StrLen(MinimumStock) = 4;
                                end;

                                if StrLen(MaximumStock) < 4 then begin
                                    repeat
                                        MaximumStock := '0' + MaximumStock;
                                    until StrLen(MaximumStock) = 4;
                                end;
                                if ArticleType <> 'Manual Station' then begin
                                    ArticleRequest += 'S0404' + MinimumStock + MaximumStock;
                                end;

                                #endregion

                                #Region Overstock storage location identifier
                                if StrLen(OverstockStorageLocation) < 12 then begin
                                    repeat
                                        OverstockStorageLocation := ' ' + OverstockStorageLocation;
                                    until StrLen(OverstockStorageLocation) = 12;
                                end;
                                if ArticleType <> 'Manual Station' then begin
                                    ArticleRequest += 'T0312' + GetOverstockStation(L_KnappItemDetails) + OverstockStorageLocation;
                                end;
                                #endregion

                                #Region Inserting Entry in Knapp Document Queue Table
                                //The Seperator Symbol is Long Dash (—)
                                Clear(DocumentReference);
                                DocumentReference := L_ItemReference."Item No." + '—' + L_ItemReference."Reference No." + '—' +
                                Format(L_KnappItemDetails."Entry No.") + '—' + Format(L_KnappItemDimensions."Entry No.");

                                IsArticleExist := false;
                                IsArticleExist := CheckArticleExist(DocumentReference);

                                if IsArticleExist = false then begin
                                    Clear(G_KnappDocumentQueue);
                                    G_KnappDocumentQueue.Reset();
                                    G_KnappDocumentQueue.Init();

                                    Clear(Rec_KnappDocumentQueue);
                                    Rec_KnappDocumentQueue.Reset();
                                    Rec_KnappDocumentQueue.SetRange("Document Type", Rec_KnappDocumentQueue."Document Type"::"Article Master");
                                    if Rec_KnappDocumentQueue.FindLast() then
                                        G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
                                    else
                                        G_KnappDocumentQueue."Entry No." := 1;

                                    G_KnappDocumentQueue."User ID" := UserId;
                                    G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Article Master";
                                    G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
                                    G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
                                    G_KnappDocumentQueue.Request := CopyStr(ArticleRequest, 1, 2048);
                                    G_KnappDocumentQueue."Document Reference No." := DocumentReference;

                                    G_KnappDocumentQueue.Insert();
                                    EntryInserted := true;
                                end;
                                #endregion
                            end;
                        until L_KnappItemDetails.Next() = 0;
                    end;

                    if EntryInserted = true then
                        L_ItemReference."Sent to Knapp" := true;
                    L_ItemReference.Modify();
                    Commit();
                end;
            until L_ItemReference.Next() = 0;
        end;
    end;

    procedure DeleteCustomerMasters()
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
        L_Customer: Record Customer;
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter("Document Type", '%1|%2', L_KnappDocumentQueue."Document Type"::"Customer Master", L_KnappDocumentQueue."Document Type"::"Customer Update");
        if L_KnappDocumentQueue.FindSet() then begin
            repeat
                L_Customer.Reset();
                L_Customer.SetRange("No.", L_KnappDocumentQueue."Document Reference No.");
                L_Customer.SetRange("Sent to Knapp", true);
                if L_Customer.FindFirst() then begin
                    L_Customer."Sent to Knapp" := false;
                    L_Customer.Modify();
                end;

                L_KnappDocumentQueue.Delete();
                Commit();
            until L_KnappDocumentQueue.Next() = 0;
        end;
    end;

    procedure GenerateInitialCustomerMaster()
    var
        L_Customer: Record Customer;
        Windows: Dialog;
        Text001: TextConst ENU = 'Generating Customer Masters..';
    begin
        Windows.OPEN(Text001 + ' @1@@@@@@@@@@@@@\' + 'Customer Master Sync..' + ' #3##########' + 'Please Wait..');
        L_Customer.Reset();
        L_Customer.SetRange(Blocked, L_Customer.Blocked::" ");
        L_Customer.SetFilter(Name, '<>%1', '');
        L_Customer.SetRange("Knapp Customer", true);
        L_Customer.SetRange("Sent to Knapp", false);
        if L_Customer.FindSet() then begin
            NoOfRecs := L_Customer.Count;
            repeat
                ClearCustomerMasterVariables();

                ProgressCount += 1;
                IF NoOfRecs <= 100 THEN
                    Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1)
                ELSE
                    IF Count MOD (NoOfRecs DIV 100) = 0 THEN
                        Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1);
                Windows.UPDATE(3, L_Customer."No.");

                #Region Data record identifier
                CustomerNo := CopyStr(L_Customer."No.", 1, 12);
                if StrLen(CustomerNo) < 12 then begin
                    repeat
                        CustomerNo += ' ';
                    until StrLen(CustomerNo) = 12;
                end;

                CustomerRequest := '15N12' + CustomerNo;
                #endregion

                #Region Identifier for customer name 1
                CustomerName := CopyStr(L_Customer.Name, 1, 30);
                if StrLen(CustomerName) < 30 then begin
                    repeat
                        CustomerName += ' ';
                    until StrLen(CustomerName) = 30;
                end;

                CustomerRequest += 'N30' + CustomerName;
                #endregion

                #Region Street identifier
                CustomerStreet := CopyStr(L_Customer.Address, 1, 30);
                if StrLen(CustomerStreet) < 30 then begin
                    repeat
                        CustomerStreet += ' ';
                    until StrLen(CustomerStreet) = 30;
                end;

                CustomerRequest += 'S30' + CustomerStreet;
                #endregion

                #Region City/town identifier
                CustomerCity := CopyStr(L_Customer.City, 1, 30);
                if StrLen(CustomerCity) < 30 then begin
                    repeat
                        CustomerCity += ' ';
                    until StrLen(CustomerCity) = 30;
                end;

                CustomerRequest += 'P30' + CustomerCity;
                #endregion

                #Region Post code identifier
                CustomerPostCode := CopyStr(L_Customer."Post Code", 1, 10);
                if StrLen(CustomerPostCode) < 10 then begin
                    repeat
                        CustomerPostCode += ' ';
                    until StrLen(CustomerPostCode) = 10;
                end;

                CustomerRequest += 'Z10' + CustomerPostCode;
                #endregion

                #Region Additional text identifier
                if StrLen(CustomerAdditionalText) < 40 then begin
                    repeat
                        CustomerAdditionalText += ' ';
                    until StrLen(CustomerAdditionalText) = 40;
                end;

                CustomerRequest += 'T40' + CustomerAdditionalText;
                #endregion

                #Region Inserting Entry in Knapp Document Queue Table
                if CheckCustomerExist(L_Customer) = false then begin
                    Clear(G_KnappDocumentQueue);
                    G_KnappDocumentQueue.Reset();
                    G_KnappDocumentQueue.Init();

                    Rec_KnappDocumentQueue.Reset();
                    Rec_KnappDocumentQueue.SetRange("Document Type", Rec_KnappDocumentQueue."Document Type"::"Customer Master");
                    if Rec_KnappDocumentQueue.FindLast() then
                        G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
                    else
                        G_KnappDocumentQueue."Entry No." := 1;

                    G_KnappDocumentQueue."User ID" := UserId;
                    G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Customer Master";
                    G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
                    G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
                    G_KnappDocumentQueue.Request := CopyStr(CustomerRequest, 1, 2048);
                    G_KnappDocumentQueue."Document Reference No." := L_Customer."No.";
                    G_KnappDocumentQueue.Insert();
                end;
                #endregion

                L_Customer."Sent to Knapp" := true;
                L_Customer.Modify();
                Commit();
            until L_Customer.Next() = 0;
            Windows.Close();
        end;
    end;

    procedure DeleteRouteMasters()
    var
        L_KnappDocumentQueue: Record "Knapp Document Queue";
        L_ShippingAgentService: Record "Shipping Agent Services";
    begin
        L_KnappDocumentQueue.Reset();
        L_KnappDocumentQueue.SetFilter("Document Type", '%1|%2', L_KnappDocumentQueue."Document Type"::"Route Master", L_KnappDocumentQueue."Document Type"::"Route Update");
        if L_KnappDocumentQueue.FindSet() then begin
            repeat
                L_ShippingAgentService.Reset();
                L_ShippingAgentService.SetRange(Code, L_KnappDocumentQueue."Document Reference No.");
                L_ShippingAgentService.SetRange("Sent to Knapp", true);
                if L_ShippingAgentService.FindFirst() then begin
                    L_ShippingAgentService."Sent to Knapp" := false;
                    L_ShippingAgentService.Modify();
                end;

                L_KnappDocumentQueue.Delete();
                Commit();
            until L_KnappDocumentQueue.Next() = 0;
        end;
    end;

    procedure GenerateInitialRouteMaster()
    var
        L_ShippingAgentServices: Record "Shipping Agent Services";
        Windows: Dialog;
        Text001: TextConst ENU = 'Generating Route Masters..';
    begin
        Windows.OPEN(Text001 + ' @1@@@@@@@@@@@@@\' + 'Route Master Sync..' + ' #3##########' + 'Please Wait..');
        L_ShippingAgentServices.Reset();
        L_ShippingAgentServices.SetRange("Knapp Round", true);
        L_ShippingAgentServices.SetRange("Sent to Knapp", false);
        if L_ShippingAgentServices.FindSet() then begin
            NoOfRecs := L_ShippingAgentServices.Count;
            repeat
                ClearRouteMasterVariables();

                ProgressCount += 1;
                IF NoOfRecs <= 100 THEN
                    Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1)
                ELSE
                    IF Count MOD (NoOfRecs DIV 100) = 0 THEN
                        Windows.UPDATE(1, (ProgressCount / NoOfRecs * 10000) DIV 1);
                Windows.UPDATE(3, L_ShippingAgentServices.Code);

                #Region Data record identifier
                RouteNumber := CopyStr(L_ShippingAgentServices.Code, 1, 8);
                if StrLen(RouteNumber) < 8 then begin
                    repeat
                        RouteNumber += ' ';
                    until StrLen(RouteNumber) = 8;
                end;

                RouteRequest := '16N08' + RouteNumber;
                #endregion

                #Region Departure time identifier
                DepartureTime := Format(L_ShippingAgentServices."Departure Time", 0, '<Hours24,2><Minutes,2><Seconds,2>');

                if DepartureTime = ' 00000' then begin
                    DepartureTime := '000000';
                end;

                if DepartureTime.StartsWith(' ') then
                    DepartureTime := DepartureTime.TrimStart(' ');

                if StrLen(DepartureTime) < 6 then begin
                    repeat
                        DepartureTime := '0' + DepartureTime;
                    until StrLen(DepartureTime) = 6;
                end;

                RouteRequest += 'Z0600' + DepartureTime;
                #endregion

                #Region Inserting Entry in Knapp Document Queue Table
                if CheckRouteExist(L_ShippingAgentServices) = false then begin
                    Clear(G_KnappDocumentQueue);
                    G_KnappDocumentQueue.Reset();
                    G_KnappDocumentQueue.Init();

                    Rec_KnappDocumentQueue.Reset();
                    Rec_KnappDocumentQueue.SetRange("Document Type", Rec_KnappDocumentQueue."Document Type"::"Route Master");
                    if Rec_KnappDocumentQueue.FindLast() then
                        G_KnappDocumentQueue."Entry No." := Rec_KnappDocumentQueue."Entry No." + 1
                    else
                        G_KnappDocumentQueue."Entry No." := 1;

                    G_KnappDocumentQueue."User ID" := UserId;

                    G_KnappDocumentQueue."Document Type" := G_KnappDocumentQueue."Document Type"::"Route Master";
                    G_KnappDocumentQueue.Status := G_KnappDocumentQueue.Status::New;
                    G_KnappDocumentQueue."Created Date/Time" := CurrentDateTime;
                    G_KnappDocumentQueue.Request := CopyStr(RouteRequest, 1, 2048);
                    G_KnappDocumentQueue."Document Reference No." := L_ShippingAgentServices.Code;
                    G_KnappDocumentQueue.Insert();
                end;
                #endregion

                L_ShippingAgentServices."Sent to Knapp" := true;
                L_ShippingAgentServices.Modify();
                Commit();
            until L_ShippingAgentServices.Next() = 0;
        end;
    end;
    #endregion

    local procedure ClearArticleMasterVariables()
    var
    begin
        Clear(ArticleRequest);
        Clear(StationNo);
        Clear(Aisle);
        Clear(Rack);
        Clear(RackLevel);
        Clear(Position);
        Clear(PackSize);
        Clear(ArticleNo);
        Clear(Length);
        Clear(Width);
        Clear(Height);
        Clear(Weight);
        Clear(ArticleCode);
        Clear(ArticleName);
        Clear(StorageLocation);
        Clear(EjectionNo);
        Clear(MaximumQty);
        Clear(MaximumStock);
        Clear(MinimumStock);
        Clear(OverstockStorageLocation);
        Clear(ArticleType);
    end;

    local procedure ClearCustomerMasterVariables()
    var
    begin
        Clear(CustomerRequest);
        Clear(CustomerNo);
        Clear(CustomerName);
        Clear(CustomerStreet);
        Clear(CustomerCity);
        Clear(CustomerPostCode);
        Clear(CustomerAdditionalText);
    end;

    local procedure ClearRouteMasterVariables()
    var
    begin
        Clear(RouteRequest);
        Clear(RouteNumber);
        Clear(DepartureTime);
    end;

    local procedure ClearOrderVariables()
    var
    begin
        Clear(OrderRequest);
        Clear(OrderNumber);
        CheckOrderExist := false;
        Clear(OrderCustomerNo);
        Clear(OrderRouteNo);
        Clear(TotalOrderLineNo);
        TotalOrderStations := 0;
        Clear(OrderStationRequest);
        Clear(TotalStations);
    end;

    procedure CheckKnappCustomer(_CustomerNo: Code[20]): Boolean
    var
        L_Customer: Record Customer;
    begin
        if L_Customer.Get(_CustomerNo) then
            if L_Customer."Knapp Customer" = true then
                exit(true);
        exit(false);
    end;

    procedure CheckKnappItem(_ItemNo: Code[20]): Boolean
    var
        L_Item: Record Item;
    begin
        if L_Item.Get(_ItemNo) then
            if L_Item."Knapp Item" = true then
                exit(true);
        exit(false);
    end;
}