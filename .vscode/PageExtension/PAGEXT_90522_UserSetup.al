pageextension 90522 "User Setup Ext" extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("Knapp Permission"; Rec."Knapp Permission")
            {
                ApplicationArea = All;
            }
            field("Update Qty. to Ship"; Rec."Update Qty. to Ship")
            {
                ApplicationArea = All;
                Caption = 'Update Qty. to Ship (Knapp)';
            }
        }
    }
}