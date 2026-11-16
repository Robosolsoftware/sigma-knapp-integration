page 90509 "Knapp Order Responses"
{
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "Knapp Order Response";
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater("Knapp Order Responses")
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Sheet Number"; Rec."Sheet Number")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Load Unit"; Rec."Load Unit")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                    begin
                        if Rec."From Knapp" = true then
                            Error('You can not modify the quantity of this record');

                        Rec.Amount := (Rec.Quantity * Rec."Unit Price") - ((Rec.Quantity * Rec."Unit Price" * Rec."Line Discount %") / 100);
                        Rec."VAT Amount" := (ROUND((Rec.Amount * (Rec."VAT %" / 100)), 0.01, '='));
                        Rec."Amount Including VAT" := Rec.Amount + Rec."VAT Amount";
                    end;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("From Knapp"; Rec."From Knapp")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Delete Knapp Responses")
            {
                ApplicationArea = All;
                Image = Delete;

                trigger OnAction()
                var
                    L_KnappOrderResponses: Record "Knapp Order Response";
                    UserSetup: Record "User Setup";
                begin
                    UserSetup.Reset();
                    if UserSetup.Get(UserId) then begin
                        if UserSetup."Knapp Permission" = true then begin
                            Clear(L_KnappOrderResponses);
                            L_KnappOrderResponses := Rec;
                            CurrPage.SetSelectionFilter(L_KnappOrderResponses);

                            if L_KnappOrderResponses.FindSet() then begin
                                repeat
                                    L_KnappOrderResponses.Delete();
                                until L_KnappOrderResponses.Next() = 0;
                            end;
                            Message('Process Completed');
                        end
                        else begin
                            Message('You do not have permission to delete knapp order responses.');
                        end;
                    end;
                    Commit();
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    var
        UserSetup: Record "User Setup";
        L_SalesHeader: Record "Sales Header";
    begin
        if Rec."From Knapp" = true then
            Error('You can not delete Knapp order responses that came from Knapp');

        UserSetup.Reset();
        if UserSetup.Get(UserId) then begin
            if UserSetup."Knapp Permission" = false then begin
                Error('You do not have permission to delete knapp order responses.');
            end;
        end;

        L_SalesHeader.Reset();
        L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
        L_SalesHeader.SetRange("No.", Rec."Document No.");
        if L_SalesHeader.FindFirst() then begin
            L_SalesHeader.CalcFields(Shipped);
            if L_SalesHeader.Shipped = true then
                Error('You can not delete Knapp order responses for which the order has already been shipped');
        end;
    end;
}