page 90502 "Knapp Station Numbers"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Knapp Station Numbers";

    layout
    {
        area(Content)
        {
            repeater(Stations)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                }
                field("Station Number"; Rec."Station Number")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Special Check"; Rec."Special Check")
                {
                    ApplicationArea = All;
                }
                field("Final Check"; Rec."Final Check")
                {
                    ApplicationArea = All;
                }
                field(Repacking; Rec.Repacking)
                {
                    ApplicationArea = All;
                }
                field(Dispatch; Rec.Dispatch)
                {
                    ApplicationArea = All;
                }
                field(Lid; Rec.Lid)
                {
                    ApplicationArea = All;
                }
                field("Invoice Station"; Rec."Invoice Station")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}