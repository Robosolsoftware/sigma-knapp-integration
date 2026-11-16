page 90501 "Knapp Article/Dimensions"
{
    PageType = Document;
    UsageCategory = Administration;
    SourceTable = "Item Reference";

    layout
    {
        area(Content)
        {
            field("Item No."; Rec."Item No.")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Reference No."; Rec."Reference No.")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Variant Code"; Rec."Variant Code")
            {
                ApplicationArea = All;
                Editable = false;
            }
            part("Knapp Article Details"; "Knapp Article Details")
            {
                ApplicationArea = all;
                SubPageLink = "Item No." = field("Item No."), "Item Reference No." = field("Reference No."), "Item Reference Type" = field("Reference Type"), "Item Variant Code" = field("Variant Code");
                Editable = true;
            }
            part("Knapp Article Dimensions"; "Knapp Article Dimensions")
            {
                ApplicationArea = all;
                SubPageLink = "Item No." = field("Item No."), "Item Reference No." = field("Reference No."), "Item Reference Type" = field("Reference Type"), "Item Variant Code" = field("Variant Code");
                Editable = true;
            }
        }
    }
}