table 90507 "Knapp Picking Details"
{
    DataClassification = ToBeClassified;
    DrillDownPageId = "Knapp Picking Details";
    LookupPageId = "Knapp Picking Details";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "Document Type"; Enum "Sales Document Type")
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Sheet Number"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Knapp Response Exist"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Knapp Order Response" where("Document Type" = const(Order), "Document No." = field("Document No."), "Sheet Number" = field("Sheet Number")));
        }
        field(6; "Tote Number"; Code[8])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}