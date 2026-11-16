page 90503 "Knapp Article Dimensions"
{
    PageType = ListPart;
    UsageCategory = Administration;
    SourceTable = "Knapp Item Dimensions";

    layout
    {
        area(Content)
        {
            repeater(Dimensions)
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Item Reference Type"; Rec."Item Reference Type")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Pack Size"; Rec."Pack Size")
                {
                    ApplicationArea = All;
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = All;
                    Caption = 'Length (mm)';
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = All;
                    Caption = 'Width (mm)';
                }
                field(Height; Rec.Height)
                {
                    ApplicationArea = All;
                    Caption = 'Height (mm)';
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = All;
                    Caption = 'Weight (Grams)';
                }
            }
        }
    }
}