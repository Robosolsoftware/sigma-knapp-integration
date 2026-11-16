pageextension 90520 "Item Lookup Ext" extends "Item Lookup"
{
    layout
    {
        addafter(Description)
        {
            field("Knapp Item"; Rec."Knapp Item")
            {
                ApplicationArea = All;
            }
            field("Knapp Threshold Quantity"; Rec."Knapp Threshold Quantity")
            {
                ApplicationArea = All;
            }
        }
    }
}