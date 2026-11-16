pageextension 90511 "Posted Sales Invoice List Ext" extends "Posted Sales Invoices"
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
    }
}