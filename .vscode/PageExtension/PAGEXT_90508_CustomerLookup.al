pageextension 90508 "Customer Lookup Ext" extends "Customer Lookup"
{
    layout
    {
        addafter(Name)
        {
            field("Knapp Customer"; Rec."Knapp Customer")
            {
                ApplicationArea = All;
            }
        }
    }
}