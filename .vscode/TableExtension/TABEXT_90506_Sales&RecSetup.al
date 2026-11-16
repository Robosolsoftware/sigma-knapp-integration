tableextension 90506 "Sales & Receivables Setup Ext" extends "Sales & Receivables Setup"
{
    fields
    {
        field(90500; "eVo Upload Key"; Code[250])
        {
            DataClassification = ToBeClassified;
        }
        field(90501; "Knapp Sheet Validation"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90502; "Stop Duplicate KNAPP Posting"; Boolean)
        {
            DataClassification = ToBeClassified;
            ToolTip = 'Specifies a field to prevent duplicate KNAPP postings';
        }
    }
}