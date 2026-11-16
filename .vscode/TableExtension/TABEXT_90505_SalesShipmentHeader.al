tableextension 90505 "Sales Shipment Header Ext." extends "Sales Shipment Header"
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