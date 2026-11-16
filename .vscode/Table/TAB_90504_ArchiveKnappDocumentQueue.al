table 90504 "Archive Knapp Document Queue"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            TableRelation = User."User Name";
            DataClassification = ToBeClassified;
        }
        field(3; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionMembers = " ","Article Master","Customer Master","Route Master",Order,"Order Update",Invoice;
            OptionCaption = ' ,Article Master,Customer Master,Route Master,Order,Order Update,Invoice';
            DataClassification = ToBeClassified;
        }
        field(4; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'New,Processing,Completed,Error';
            OptionMembers = New,Processing,Completed,Error;
            DataClassification = ToBeClassified;
        }
        field(5; "Created Date/Time"; DateTime)
        {
            Caption = 'Created Date/Time';
            Editable = true;
            DataClassification = ToBeClassified;
        }
        field(6; "Request"; Text[2048])
        {
            Caption = 'Request';
            DataClassification = ToBeClassified;
        }
        field(7; "Response"; Text[2048])
        {
            Caption = 'Response';
            DataClassification = ToBeClassified;
        }
        field(8; "Updated Date/Time"; DateTime)
        {
            Caption = 'Updated Date/Time';
            Editable = true;
            DataClassification = ToBeClassified;
        }
        field(9; Remarks; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Document Reference No."; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Moved to Archive"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(12; "Converted to Non-Knapp"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(13; Update; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(14; "Marked as Error"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
        }
    }

    internal procedure GetRequestXMLAsText() ReturnXMLAsText: Text
    var
    begin
        exit(Rec.Request);
    end;

    internal procedure GetResponseXMLAsText() ReturnXMLAsText: Text
    var
    begin
        exit(Rec.Response);
    end;
}