pageextension 90523 "Sales Lines Ext" extends "Sales Lines"
{
    layout
    {
        addafter("Qty. to Ship")
        {
            field("Knapp Qty. to Ship"; Rec."Knapp Qty. to Ship")
            {
                ApplicationArea = All;
            }
        }
    }
}