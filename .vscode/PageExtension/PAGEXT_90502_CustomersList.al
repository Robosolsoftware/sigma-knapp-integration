pageextension 90502 "Customers List Ext" extends "Customer List"
{
    layout
    {
        addafter("Payments (LCY)")
        {
            field("Knapp Customer"; Rec."Knapp Customer")
            {
                ApplicationArea = All;
            }
            field("Knapp Document"; Rec."Sent to Knapp")
            {
                ApplicationArea = All;
                Caption = 'Sent to Knapp';
                Editable = false;
            }
        }
    }

    actions
    {
        addafter("Customer Register")
        {
            action("Delete Multiple Customers")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                Image = Delete;
                Visible = false;

                trigger OnAction()
                var
                    Customers: Record Customer;
                begin
                    Clear(Customers);
                    Customers := Rec;
                    CurrPage.SetSelectionFilter(Customers);

                    if Customers.FindSet() then begin
                        repeat
                            Customers.Delete(true);
                        until Customers.Next() = 0;
                    end;
                end;
            }
        }
    }
}