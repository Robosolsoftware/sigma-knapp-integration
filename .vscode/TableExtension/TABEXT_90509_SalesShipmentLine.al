tableextension 90509 "Sales Shipment Line Ext." extends "Sales Shipment Line"
{
    fields
    {
        field(90500; "Knapp Item"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90501; "Sent to Knapp"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90502; "Knapp Line"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90503; Remarks; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(90504; "Sheet Number"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(90505; "Load Unit"; Code[8])
        {
            DataClassification = ToBeClassified;
        }
    }
}