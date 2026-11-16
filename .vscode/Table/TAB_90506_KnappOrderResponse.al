table 90506 "Knapp Order Response"
{
    DataClassification = ToBeClassified;
    LookupPageId = "Knapp Order Responses";
    DrillDownPageId = "Knapp Order Responses";

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
        field(4; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(6; Description; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Unit of Measure"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(8; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
        }
        field(9; "Unit Price"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(10; Amount; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
        }
        field(11; "Amount Including VAT"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
        }
        field(12; "VAT %"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
        }
        field(13; "VAT Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(14; "Sheet Number"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(15; "Load Unit"; Code[8])
        {
            DataClassification = ToBeClassified;
        }
        field(16; "Line Discount %"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(17; "VAT Identifier"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(18; "Variant Code"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(19; "From Knapp"; Boolean)
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