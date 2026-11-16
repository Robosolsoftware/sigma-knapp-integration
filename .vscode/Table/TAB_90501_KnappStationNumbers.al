table 90501 "Knapp Station Numbers"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "Station Number"; Code[3])
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if (StrLen(Rec."Station Number") < 3) or (StrLen(Rec."Station Number") > 3) then
                    Error('There should be 3 characters in the station number');
            end;
        }
        field(3; Type; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "Manual Station","SDA/Aframes";
            OptionCaption = 'Manual Station,SDA/Aframes';
        }
        field(4; Description; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Special Check"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Final Check"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(7; Repacking; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(8; Dispatch; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(9; Lid; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Invoice Station"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Entry No.", "Station Number")
        {
            Clustered = true;
        }
    }
}