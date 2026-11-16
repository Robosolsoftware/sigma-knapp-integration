pageextension 90527 "KNP Replenishment Master" extends "Replenishment Master List"
{
    layout
    {
        // Add changes to page layout here
        addafter("Item Description")
        {
            field("KNAPP Item"; Rec."KNAPP Item")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}