page 90508 "Delete Order Filter"
{
    PageType = StandardDialog;
    UsageCategory = Administration;
    SourceTable = "Order Filter Table";

    layout
    {
        area(Content)
        {
            group("Order Filter")
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Type in a specific entry number or a range of entry numbers';
                }
            }
        }
    }
}