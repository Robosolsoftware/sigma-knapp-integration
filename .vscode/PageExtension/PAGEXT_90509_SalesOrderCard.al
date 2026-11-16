pageextension 90509 "Sales Order Card Ext." extends "Sales Order"
{
    layout
    {
        addafter(SystemModifiedBy)
        {
            field("Knapp Customer"; Rec."Knapp Customer")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Knapp Order"; Rec."Knapp Order")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Sent to Knapp"; Rec."Sent to Knapp")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Sent Knapp Invoice"; Rec."Sent Knapp Invoice")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Knapp Invoice Remark"; Rec."Knapp Invoice Remark")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Order Complete"; Rec."Order Complete")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }


    actions
    {
        modify("Create Inventor&y Put-away/Pick")
        {
            Visible = false;
            Enabled = false;

            trigger OnBeforeAction()
            var
            begin
                Error('Use Create Invt. Pick Report');
            end;
        }

        addafter("Create Inventor&y Put-away/Pick")
        {
            action("Create Inventor Pick")
            {
                AccessByPermission = TableData "Posted Invt. Pick Header" = R;
                ApplicationArea = Warehouse;
                Caption = 'Create Invt. Pick';
                Ellipsis = true;
                Image = CreateInventoryPickup;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Create an inventory put-away or inventory pick to handle items on the document according to a basic warehouse configuration that does not require warehouse receipt or shipment documents.';

                trigger OnAction()
                begin
                    //Check Manual Order
                    Rec.TestField("Knapp Order", false);

                    Rec.PerformManualRelease();
                    Rec.CreateInvtPutAwayPick_Copy();

                    if not Rec.Find('=><') then
                        Rec.Init();
                end;
            }
            action("Export Knapp Invoice XML")
            {
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Report;
                Image = XMLFile;
                ApplicationArea = All;

                trigger OnAction()
                var
                    L_KnappSalesInvoice: xmlport "Knapp Sales Invoice";
                    L_SalesHeader: Record "Sales Header";
                    CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                begin
                    Clear(L_KnappSalesInvoice);
                    Clear(L_SalesHeader);
                    L_SalesHeader := Rec;
                    CurrPage.SetSelectionFilter(L_SalesHeader);

                    L_SalesHeader.SetRange("Knapp Order", true);
                    if L_SalesHeader.FindSet() then begin
                        repeat
                            L_KnappSalesInvoice.SetTableView(L_SalesHeader);
                            L_KnappSalesInvoice.Run();
                        until L_SalesHeader.Next() = 0;
                    end;
                end;
            }
        }
        addafter(AssemblyOrders)
        {
            action("Knapp Picking Details")
            {
                ApplicationArea = Basic, Suite;
                Image = ViewDetails;
                RunObject = Page "Knapp Picking Details";
                RunPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                ToolTip = 'This will show the details of total sheets in which the order was split';

                trigger OnAction()
                var
                    L_SalesHeader: Record "Sales Header";
                    L_KnappPickingDetails: Record "Knapp Picking Details";
                    L_KnappOrderResponse: Record "Knapp Order Response";
                begin
                    Clear(L_SalesHeader);
                    L_SalesHeader := Rec;
                    CurrPage.SetSelectionFilter(L_SalesHeader);

                    if L_SalesHeader.FindFirst() then begin
                        L_KnappPickingDetails.Reset();
                        L_KnappPickingDetails.SetRange("Document Type", L_KnappPickingDetails."Document Type"::Order);
                        L_KnappPickingDetails.SetRange("Document No.", L_SalesHeader."No.");
                        L_KnappPickingDetails.SetFilter("Tote Number", '%1', '');
                        if L_KnappPickingDetails.FindSet() then begin
                            repeat
                                L_KnappOrderResponse.Reset();
                                L_KnappOrderResponse.SetRange("Document Type", L_KnappOrderResponse."Document Type"::Order);
                                L_KnappOrderResponse.SetRange("Document No.", L_SalesHeader."No.");
                                L_KnappOrderResponse.SetRange("Sheet Number", L_KnappPickingDetails."Sheet Number");
                                if L_KnappOrderResponse.FindFirst() then begin
                                    L_KnappPickingDetails."Tote Number" := L_KnappOrderResponse."Load Unit";
                                    L_KnappPickingDetails.Modify();
                                end;
                            until L_KnappPickingDetails.Next() = 0;
                        end;
                    end;
                end;
            }

            action("Mark Order Completed")
            {
                ApplicationArea = Basic, Suite;
                Image = Completed;

                trigger OnAction()
                var
                    CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                    L_KnappPickingDetails: Record "Knapp Picking Details";
                    L_SalesHeader: Record "Sales Header";
                begin
                    Clear(L_SalesHeader);
                    L_SalesHeader := Rec;
                    CurrPage.SetSelectionFilter(L_SalesHeader);

                    if L_SalesHeader.FindFirst() then begin
                        L_SalesHeader.CalcFields("Sent to Knapp", Shipped);
                        if L_SalesHeader."Knapp Order" = false then
                            Error('You can not mark order complete for non Knapp order');
                        if L_SalesHeader."Sent to Knapp" = false then
                            Error('You can not mark order complete for Order which is not yet sent to knapp');
                        if L_SalesHeader.Shipped = true then
                            Error('You can not mark order complete for already shipped order');

                        if Confirm('Do you really want to mark this Order as Complete?') then begin
                            L_SalesHeader."Order Complete" := true;
                            L_SalesHeader.Modify();
                        end;
                    end;
                end;
            }
        }
    }
}