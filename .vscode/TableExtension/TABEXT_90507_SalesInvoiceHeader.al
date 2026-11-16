tableextension 90507 "Sales Invoice Header Ext" extends "Sales Invoice Header"
{
    fields
    {
        field(90500; "Knapp Customer"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90501; "Knapp Order"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }
}