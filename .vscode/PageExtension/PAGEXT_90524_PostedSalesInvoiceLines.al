pageextension 90524 "Post. Sales Invoice Lines Ext" extends "Posted Sales Invoice Lines"
{
    layout
    {
        addafter(Quantity)
        {
            field("Knapp Qty. to Ship"; Rec."Knapp Qty. to Ship")
            {
                ApplicationArea = All;
            }
        }
    }
}