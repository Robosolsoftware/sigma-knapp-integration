table 90505 "Order Filter Table"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary key"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Shipment Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(3; Shift; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = E,A,M,X," ";
            OptionCaption = 'E,A,M,X, ';
        }
        field(4; "Document Type"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = Order;
            OptionCaption = 'Order';
        }
        field(5; Status; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = 'New,Error,Completed';
            OptionMembers = New,Error,Completed;
        }
        field(6; "Entry No."; Code[100])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "No. of Orders to Process"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Tote Number"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Sheet Number"; Integer)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Primary key")
        {
            Clustered = true;
        }
    }
}