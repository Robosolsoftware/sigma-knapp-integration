codeunit 90503 "Knapp Events"
{

    SingleInstance = true;

    var
        G_KNAPPOrder: Boolean;
        G_OrderCategory: Option "Standard Order","Knapp Order";

    [EventSubscriber(ObjectType::Table, Database::"Knapp Document Queue", 'OnAfterInsertEvent', '', true, true)]
    local procedure OnAfterInsertKnappDocumentQueue(var Rec: Record "Knapp Document Queue"; RunTrigger: Boolean)
    var
        CU_KnappGenerateDocuments: Codeunit "Knapp Generate Documents";
    begin
        Commit();
        if (Rec."Document Type" = Rec."Document Type"::"Order Update") and (Rec.Status = Rec.Status::New) then begin
            CU_KnappGenerateDocuments.SyncOrderResponses(Rec);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterManualReleaseSalesDoc', '', false, false)]
    local procedure OnAfterManualReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    var
        L_Location: Record Location;
        L_SalesLine: Record "Sales Line";
    begin
        if (SalesHeader.Status = SalesHeader.Status::Released) and (SalesHeader."Knapp Order" = true) then begin
            L_Location.Reset();
            L_Location.SetRange("Knapp Location", true);
            if L_Location.FindFirst() then begin
                if L_Location.Code <> SalesHeader."Location Code" then begin
                    SalesHeader."Location Code" := L_Location.Code;
                    SalesHeader.Modify();

                    L_SalesLine.Reset();
                    L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                    L_SalesLine.SetRange("Document No.", SalesHeader."No.");
                    if L_SalesLine.FindSet() then begin
                        repeat
                            L_SalesLine."Location Code" := L_Location.Code;
                            L_SalesLine.Modify();
                        until L_SalesLine.Next() = 0;
                    end;
                end;
            end;
        end;
    end;

    #Region Knapp Sales Order Post using Report - "Batch Post Sales Orders" (296)
    procedure GetOrderCategoryFilter(_OrderCategory: Option "Standard Order","Knapp Order"): Text
    begin
        //get the order category from request page filter
        Clear(G_OrderCategory);
        G_OrderCategory := _OrderCategory;
    end;


    [EventSubscriber(ObjectType::Report, Report::"Batch Post Sales Orders", 'OnBeforeSalesBatchPostMgt', '', false, false)]
    local procedure OnBeforeSalesBatchPostMgt(var SalesHeader: Record "Sales Header")
    var
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
    begin
        // For knapp orders
        if G_OrderCategory = G_OrderCategory::"Knapp Order" then begin
            SalesHeader.CalcFields("Sent to Knapp", "Knapp Response Available");
            SalesHeader.SetRange("Knapp Order", true);
            SalesHeader.SetRange("Order Complete", true);
            SalesHeader.SetRange("Sent to Knapp", true);
            SalesHeader.SetRange("Knapp Response Available", true);
        end;

        // For standard orders
        if G_OrderCategory = G_OrderCategory::"Standard Order" then begin
            SalesHeader.SetRange("Knapp Order", false);
            SalesHeader.SetRange("Inv. Pick Exist", false);
            SalesHeader.SetRange("Shipped", true);
            //SalesHeader.SetRange("Shipped Not Invoiced", true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnInvokeProcessingOnBeforeRunProcessingCodeunitID', '', false, false)]
    local procedure OnInvokeProcessingOnBeforeRunProcessingCodeunitID(RecordRef: RecordRef)
    var
        RecVar: Variant;
        L_SalesHeader: Record "Sales Header";
        L_SalesLine: Record "Sales Line";
        L_KnappPickingDetails: Record "Knapp Picking Details";
        PickingExist: Boolean;
        L_SalesAndRecSetup: Record "Sales & Receivables Setup";
    begin
        if G_OrderCategory = G_OrderCategory::"Knapp Order" then begin
            L_SalesAndRecSetup.Get();
            if L_SalesAndRecSetup."Stop Duplicate KNAPP Posting" = false then begin
                PickingExist := true;
                Clear(L_SalesHeader);
                RecVar := RecordRef;
                if RecordRef.Number = 36 then
                    L_SalesHeader := RecVar;

                if L_SalesAndRecSetup."Knapp Sheet Validation" = true then begin
                    L_KnappPickingDetails.Reset();
                    L_KnappPickingDetails.SetRange("Document Type", L_KnappPickingDetails."Document Type"::Order);
                    L_KnappPickingDetails.SetRange("Document No.", L_SalesHeader."No.");
                    if L_KnappPickingDetails.FindSet() then begin
                        repeat
                            L_KnappPickingDetails.CalcFields("Knapp Response Exist");
                            if L_KnappPickingDetails."Knapp Response Exist" = false then
                                PickingExist := false;
                        until L_KnappPickingDetails.Next() = 0;
                    end;
                end;

                if (L_SalesHeader."Knapp Order" = true) and (PickingExist = true) then begin
                    L_SalesLine.Reset();
                    L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type");
                    L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                    L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                    L_SalesLine.SetRange("Knapp Line", true);
                    if L_SalesLine.FindSet() then begin
                        repeat
                            L_SalesLine.CalcFields("Knapp Qty. to Ship");
                            if L_SalesLine."Knapp Qty. to Ship" <= L_SalesLine.Quantity then begin
                                L_SalesLine.Validate("Qty. to Ship", L_SalesLine."Knapp Qty. to Ship");
                                L_SalesLine.Validate("Qty. to Invoice", L_SalesLine."Knapp Qty. to Ship");
                                L_SalesLine.Modify();
                            end;
                        until L_SalesLine.Next() = 0;
                    end;
                    Commit();
                end;
            end;
        end;
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnVerifyRecord', '', false, false)]
    // local procedure OnVerifyRecord(var RecRef: RecordRef; var Result: Boolean)
    // var
    //     RecVar: Variant;
    //     L_SalesHeader: Record "Sales Header";
    //     L_SalesLine: Record "Sales Line";
    //     L_KnappPickingDetails: Record "Knapp Picking Details";
    //     PickingExist: Boolean;
    //     L_SalesAndRecSetup: Record "Sales & Receivables Setup";
    //     L_KnappResponse: Record "Knapp Order Response";
    //     L_KnappResponseDuplicate: Record "Knapp Order Response";
    // begin
    // if G_OrderCategory = G_OrderCategory::"Knapp Order" then begin
    //     L_SalesAndRecSetup.Get();
    //     if L_SalesAndRecSetup."Stop Duplicate KNAPP Posting" = true then begin
    //         PickingExist := true;
    //         Clear(L_SalesHeader);
    //         RecVar := RecRef;
    //         if RecRef.Number = 36 then
    //             L_SalesHeader := RecVar;

    //         if L_SalesAndRecSetup."Knapp Sheet Validation" = true then begin
    //             L_KnappPickingDetails.Reset();
    //             L_KnappPickingDetails.SetRange("Document Type", L_KnappPickingDetails."Document Type"::Order);
    //             L_KnappPickingDetails.SetRange("Document No.", L_SalesHeader."No.");
    //             if L_KnappPickingDetails.FindSet() then begin
    //                 repeat
    //                     L_KnappPickingDetails.CalcFields("Knapp Response Exist");
    //                     if L_KnappPickingDetails."Knapp Response Exist" = false then
    //                         PickingExist := false;
    //                 until L_KnappPickingDetails.Next() = 0;
    //             end;
    //         end;

    //         if (L_SalesHeader."Knapp Order" = true) and (PickingExist = true) then begin
    //             L_SalesLine.Reset();
    //             L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type");
    //             L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
    //             L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
    //             L_SalesLine.SetRange("Knapp Line", true);
    //             if L_SalesLine.FindSet() then begin
    //                 repeat
    //                     L_SalesLine.CalcFields("Knapp Qty. to Ship");
    //                     if L_SalesLine."Knapp Qty. to Ship" <= L_SalesLine.Quantity then begin
    //                         L_KnappResponse.Reset();
    //                         L_KnappResponse.SetRange("Document Type", L_KnappResponse."Document Type"::Order);
    //                         L_KnappResponse.SetRange("Document No.", L_SalesHeader."No.");
    //                         L_KnappResponse.SetRange("Line No.", L_SalesLine."Line No.");
    //                         L_KnappResponse.SetRange("Item No.", L_SalesLine."No.");
    //                         L_KnappResponse.SetFilter(Quantity, '>%1', 0);
    //                         if L_KnappResponse.FindSet() then begin
    //                             repeat
    //                                 L_KnappResponseDuplicate.Reset();
    //                                 L_KnappResponseDuplicate.SetRange("Document Type", L_KnappResponse."Document Type");
    //                                 L_KnappResponseDuplicate.SetRange("Document No.", L_KnappResponse."Document No.");
    //                                 L_KnappResponseDuplicate.SetRange("Line No.", L_KnappResponse."Line No.");
    //                                 L_KnappResponseDuplicate.SetRange("Item No.", L_KnappResponse."Item No.");
    //                                 L_KnappResponseDuplicate.SetRange(Quantity, L_KnappResponse.Quantity);
    //                                 L_KnappResponseDuplicate.SetRange("Load Unit", L_KnappResponse."Load Unit");
    //                                 //L_KnappResponseDuplicate.SetFilter(Quantity, '>%1', 0);
    //                                 if L_KnappResponseDuplicate.FindSet() then begin
    //                                     if L_KnappResponseDuplicate.Count > 1 then begin
    //                                         Result := false;
    //                                         break
    //                                     end;
    //                                 end;
    //                             until L_KnappResponse.Next() = 0;
    //                         end;
    //                     end else begin
    //                         Result := false;
    //                         break;
    //                     end;
    //                 until L_SalesLine.Next() = 0;
    //             end else
    //                 Result := false;
    //         end else
    //             Result := false;

    //         //Update Qty to Ship and Qty to Invoice ++++
    //         if Result = true then begin
    //             L_SalesLine.Reset();
    //             L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type");
    //             L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
    //             L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
    //             L_SalesLine.SetRange("Knapp Line", true);
    //             if L_SalesLine.FindSet() then begin
    //                 repeat
    //                     L_SalesLine.CalcFields("Knapp Qty. to Ship");
    //                     L_SalesLine.Validate("Qty. to Ship", L_SalesLine."Knapp Qty. to Ship");
    //                     L_SalesLine.Validate("Qty. to Invoice", L_SalesLine."Knapp Qty. to Ship");
    //                     L_SalesLine.Modify();
    //                 until L_SalesLine.Next() = 0;
    //             end;
    //             Commit();
    //         end;
    //     end;
    // end;
    // end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnVerifyRecord', '', false, false)]
    local procedure OnVerifyRecord(var RecRef: RecordRef; var Result: Boolean)
    var
        RecVar: Variant;
        L_SalesHeader: Record "Sales Header";
        L_SalesLine: Record "Sales Line";
        L_KnappPickingDetails: Record "Knapp Picking Details";
        PickingExist: Boolean;
        L_SalesAndRecSetup: Record "Sales & Receivables Setup";
        L_KnappResponse: Record "Knapp Order Response";
        L_KnappResponseDuplicate: Record "Knapp Order Response";
    begin
        if G_OrderCategory = G_OrderCategory::"Knapp Order" then begin
            L_SalesAndRecSetup.Get();
            if L_SalesAndRecSetup."Stop Duplicate KNAPP Posting" = true then begin
                PickingExist := true;
                Clear(L_SalesHeader);
                RecVar := RecRef;
                if RecRef.Number = 36 then
                    L_SalesHeader := RecVar;

                if L_SalesAndRecSetup."Knapp Sheet Validation" = true then begin
                    L_KnappPickingDetails.Reset();
                    L_KnappPickingDetails.SetRange("Document Type", L_KnappPickingDetails."Document Type"::Order);
                    L_KnappPickingDetails.SetRange("Document No.", L_SalesHeader."No.");
                    if L_KnappPickingDetails.FindSet() then begin
                        repeat
                            L_KnappPickingDetails.CalcFields("Knapp Response Exist");
                            if L_KnappPickingDetails."Knapp Response Exist" = false then
                                PickingExist := false;
                        until L_KnappPickingDetails.Next() = 0;
                    end;
                end;

                if (L_SalesHeader."Knapp Order" = true) and (PickingExist = true) then begin
                    L_SalesLine.Reset();
                    L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type");
                    L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                    L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                    L_SalesLine.SetRange("Knapp Line", true);
                    if L_SalesLine.FindSet() then begin
                        repeat
                            L_SalesLine.CalcFields("Knapp Qty. to Ship");
                            if L_SalesLine."Knapp Qty. to Ship" > L_SalesLine.Quantity then begin
                                Result := false;
                                break;
                            end;
                        until L_SalesLine.Next() = 0;
                    end else
                        Result := false;
                end else
                    Result := false;

                //Update Qty to Ship and Qty to Invoice ++++
                if Result = true then begin
                    L_SalesLine.Reset();
                    L_SalesLine.SetRange("Document Type", L_SalesHeader."Document Type");
                    L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                    L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                    L_SalesLine.SetRange("Knapp Line", true);
                    if L_SalesLine.FindSet() then begin
                        repeat
                            L_SalesLine.CalcFields("Knapp Qty. to Ship");
                            L_SalesLine.Validate("Qty. to Ship", L_SalesLine."Knapp Qty. to Ship");
                            L_SalesLine.Validate("Qty. to Invoice", L_SalesLine."Knapp Qty. to Ship");
                            L_SalesLine.Modify();
                        until L_SalesLine.Next() = 0;
                    end;
                    Commit();
                end;
            end;
        end;
    end;

    //Calling Event after Post Batch to Clear Qty. to Ship from Knapp Sales Order that gets added by default
    [EventSubscriber(ObjectType::Report, Report::"Batch Post Sales Orders", 'OnAfterSalesBatchPostMgt', '', false, false)]
    local procedure OnAfterSalesBatchPostMgt(var SalesHeader: Record "Sales Header")
    var
        L_SalesLine: Record "Sales Line";
        CU_ReleaseSalesDoc: Codeunit "Release Sales Document";
        OrderReOpened: Boolean;
        L_SalesHeader: Record "Sales Header";
    begin
        if G_OrderCategory = G_OrderCategory::"Knapp Order" then begin
            Commit();
            OrderReOpened := false;
            L_SalesHeader.Reset();
            L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
            L_SalesHeader.SetRange("No.", SalesHeader."No.");
            if L_SalesHeader.FindFirst() then begin
                L_SalesHeader.CalcFields(Shipped);
                if (L_SalesHeader."Knapp Order" = true) and (L_SalesHeader.Shipped = true) then begin
                    if L_SalesHeader.Status = L_SalesHeader.Status::Released then begin
                        CU_ReleaseSalesDoc.PerformManualReopen(L_SalesHeader);
                        OrderReOpened := true;
                    end;

                    L_SalesLine.Reset();
                    L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                    L_SalesLine.SetRange("Document No.", L_SalesHeader."No.");
                    L_SalesLine.SetFilter("Qty. to Ship", '>0');
                    if L_SalesLine.FindSet() then begin
                        repeat
                            L_SalesLine.Validate("Qty. to Ship", 0);
                            L_SalesLine.Modify(true);
                        until L_SalesLine.Next() = 0;
                    end;

                    if OrderReOpened = true then
                        CU_ReleaseSalesDoc.PerformManualRelease(L_SalesHeader);
                end;
            end;
        end;
    end;


    //Post Order even custometr is Blocked+++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeCheckCustBlockage', '', false, false)]
    local procedure OnBeforeCheckCustBlockage(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        Clear(G_KNAPPOrder);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            if SalesHeader."Knapp Order" = true then
                IsHandled := true;

    end;
    //Post Order even custometr is Blocked+++


    //Step1++    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeItemJnlPostLine', '', false, false)]
    local procedure OnBeforeItemJnlPostLine(SalesHeader: Record "Sales Header")
    begin
        Clear(G_KNAPPOrder);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            if SalesHeader."Knapp Order" = true then
                G_KNAPPOrder := true;
    end;

    //Step2++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeCheckItemAndItemVariant', '', false, false)]
    local procedure OnBeforeCheckItemAndItemVariant(var IsHandled: Boolean)
    begin
        if G_KNAPPOrder = true then
            IsHandled := true;
    end;

    //Step3++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforeCheckIfItemIsBlocked', '', false, false)]
    local procedure OnBeforeCheckIfItemIsBlocked(var IsHandled: Boolean; var ItemJournalLine: Record "Item Journal Line")
    begin
        if G_KNAPPOrder = true then
            IsHandled := true;

        if ItemJournalLine."Variant Code" = '' then
            Clear(G_KNAPPOrder);
    end;

    //Step4++
    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnBeforeDisplayErrorIfItemVariantIsBlocked', '', false, false)]
    local procedure OnBeforeDisplayErrorIfItemVariantIsBlocked(var IsHandled: Boolean)
    begin
        if G_KNAPPOrder = true then
            IsHandled := true;

        Clear(G_KNAPPOrder);
    end;
    #endregion
}