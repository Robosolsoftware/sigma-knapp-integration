pageextension 90521 "Sales & Receivables Setup ext." extends "Sales & Receivables Setup"
{
    layout
    {
        addlast(General)
        {
            field("eVo Upload Key"; Rec."eVo Upload Key")
            {
                ApplicationArea = All;
            }
            field("Knapp Sheet Validation"; Rec."Knapp Sheet Validation")
            {
                ApplicationArea = All;
                ToolTip = 'This will refer that knapp response sheet validation is enabled or not for Sales Order';
            }
            field("Stop Duplicate KNAPP Posting"; Rec."Stop Duplicate KNAPP Posting")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies a field to prevent duplicate KNAPP postings';
            }
        }
    }
}