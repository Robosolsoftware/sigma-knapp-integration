pageextension 90541 "KI Inventory Picks" extends "Inventory Picks"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Shipping Agent Code")
        {
            field(Shift; Rec.Shift)
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Departure Time"; Rec."Departure Time")
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