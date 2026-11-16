tableextension 90502 "Customer Ext" extends Customer
{
    fields
    {
        field(90500; "Knapp Customer"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90501; "Sent to Knapp"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90502; "Knapp Special Check"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90503; "Knapp Final Check"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90504; "Knapp Invoice Station"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90505; "Knapp Repack"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90506; "Knapp Lid"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            var
            begin
                if Rec."No." <> xRec."No." then
                    Rec."Sent to Knapp" := false;
            end;
        }
        modify(Name)
        {
            trigger OnBeforeValidate()
            var
            begin
                if Rec.Name = '' then
                    Error('Customer Name is required');
            end;

            trigger OnAfterValidate()
            var
            begin
                if Rec.Name <> xRec.Name then
                    Rec."Sent to Knapp" := false;
            end;
        }
        modify(Address)
        {
            trigger OnAfterValidate()
            var
            begin
                if Rec.Address <> xRec.Address then
                    Rec."Sent to Knapp" := false;
            end;
        }
        modify(City)
        {
            trigger OnAfterValidate()
            var
            begin
                if Rec.City <> xRec.City then
                    Rec."Sent to Knapp" := false;
            end;
        }
        modify("Post Code")
        {
            trigger OnAfterValidate()
            var
            begin
                if Rec."Post Code" <> xRec."Post Code" then
                    Rec."Sent to Knapp" := false;
            end;
        }
    }
}