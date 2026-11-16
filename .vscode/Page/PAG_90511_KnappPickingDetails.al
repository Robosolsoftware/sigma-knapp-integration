page 90511 "Knapp Picking Details"
{
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "Knapp Picking Details";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater("Knapp Picking Details")
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Tote Number"; Rec."Tote Number")
                {
                    ApplicationArea = All;
                }
                field("Sheet Number"; Rec."Sheet Number")
                {
                    ApplicationArea = All;
                }
                field("Knapp Response Exist"; Rec."Knapp Response Exist")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Add Knapp Response")
            {
                ApplicationArea = Basic, Suite;
                Image = Add;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                    L_SalesHeader: Record "Sales Header";
                    L_KnappPickingDetails: Record "Knapp Picking Details";
                begin
                    Clear(L_KnappPickingDetails);
                    L_KnappPickingDetails := Rec;
                    CurrPage.SetSelectionFilter(L_KnappPickingDetails);

                    L_SalesHeader.Reset();
                    L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
                    L_SalesHeader.SetRange("No.", L_KnappPickingDetails."Document No.");
                    if L_SalesHeader.FindFirst() then begin
                        L_SalesHeader.CalcFields("Sent to Knapp", Shipped);
                        if L_SalesHeader."Knapp Order" = false then
                            Error('You can not add Knapp Responses for non Knapp order');
                        if L_SalesHeader."Sent to Knapp" = false then
                            Error('You can not add Knapp Responses for Order which is not yet sent to knapp');
                        if L_SalesHeader.Shipped = true then
                            Error('You can not add Knapp Responses for already shipped order');

                        Clear(CU_KnappGenerateDocument);
                        CU_KnappGenerateDocument.KnappManualResponse(L_SalesHeader);
                    end;
                end;
            }

            action("Mark Order Completed")
            {
                ApplicationArea = Basic, Suite;
                Image = Completed;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                    L_KnappPickingDetails: Record "Knapp Picking Details";
                    L_SalesHeader: Record "Sales Header";
                begin
                    Clear(L_KnappPickingDetails);
                    L_KnappPickingDetails := Rec;
                    CurrPage.SetSelectionFilter(L_KnappPickingDetails);

                    L_SalesHeader.Reset();
                    L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
                    L_SalesHeader.SetRange("No.", L_KnappPickingDetails."Document No.");
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