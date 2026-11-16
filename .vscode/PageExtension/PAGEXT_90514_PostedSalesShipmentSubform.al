pageextension 90514 "Posted Sales Shpt. Subform Ext" extends "Posted Sales Shpt. Subform"
{
    layout
    {
        addafter(Description)
        {
            field("Knapp Item"; Rec."Knapp Item")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Sheet Number"; Rec."Sheet Number")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Load Unit"; Rec."Load Unit")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }
    actions
    {
        addafter(UndoShipment)
        {
            action("Knapp Order Response")
            {
                ApplicationArea = Basic, Suite;
                Image = ViewDetails;
                RunObject = Page "Knapp Order Responses";
                RunPageLink = "Document Type" = const(Order), "Document No." = field("Order No.");
            }
        }
    }
}