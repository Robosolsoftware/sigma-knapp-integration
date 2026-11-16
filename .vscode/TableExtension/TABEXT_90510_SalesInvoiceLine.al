tableextension 90510 "Sales Invoice Line Ext." extends "Sales Invoice Line"
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
        field(90506; "Knapp Qty. to Ship"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Knapp Order Response".Quantity where("Document Type" = const(Order), "Document No." = field("Order No."), "Item No." = field("No."), "Line No." = field("Line No.")));
        }
    }
}