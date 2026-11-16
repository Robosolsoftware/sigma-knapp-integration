pageextension 90510 "Sales Order List Ext." extends "Sales Order List"
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("Knapp Customer"; Rec."Knapp Customer")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
        addlast(Control1)
        {
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
            field("Knapp Response Available"; Rec."Knapp Response Available")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'This field will show if Knapp Response is available or not against the Order with Quantity more than 0';
            }
            field("Knapp Response with Picks"; Rec."Knapp Response with Picks")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Order Complete"; Rec."Order Complete")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'This field will show if the Order is Finished Picking from Knapp Side or not';
            }
        }
    }


    actions
    {
        modify("Create Inventor&y Put-away/Pick")
        {
            Visible = false;

            trigger OnBeforeAction()
            var
                myInt: Integer;
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

            action("Knapp Picking Details")
            {
                ApplicationArea = Warehouse;
                Ellipsis = true;
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;
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
            action("Mark Order Complete")
            {
                ApplicationArea = all;
                trigger OnAction()
                var
                    MarkOrderComplete: Codeunit "Auto Mark Order Completed";
                begin
                    MarkOrderComplete.Run();
                end;
            }
        }
    }
}
