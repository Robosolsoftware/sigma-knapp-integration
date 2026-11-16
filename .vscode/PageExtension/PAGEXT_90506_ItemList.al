pageextension 90506 "Item List Ext" extends "Item List"
{
    layout
    {
        addlast(Control1)
        {
            field("Knapp Item"; Rec."Knapp Item")
            {
                ApplicationArea = All;
            }
        }
    }
}