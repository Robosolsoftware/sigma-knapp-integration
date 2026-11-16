tableextension 90503 "Shipping Agent Service Ext" extends "Shipping Agent Services"
{
    fields
    {
        field(90500; "Departure Time"; Time)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                Rec."Sent to Knapp" := false;
            end;
        }
        field(90501; "Sent to Knapp"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90502; "Knapp Round"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90503; Shift; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",M,A,E,X;
            OptionCaption = ' ,M,A,E,X';
            trigger OnValidate()
            var
            begin
                Rec."Sent to Knapp" := false;
            end;
        }
        modify(Code)
        {
            trigger OnAfterValidate()
            var
            begin
                Rec."Sent to Knapp" := false;
            end;
        }
    }
}