table 90502 "Knapp Item Details"
{
    DataClassification = ToBeClassified;
    DataCaptionFields = "Item No.", "Item Reference No.";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item."No.";
        }
        field(3; "Item Reference No."; Code[50])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Reference"."Reference No.";
        }
        field(4; "Item Reference Type"; Enum "Item Reference Type")
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Reference"."Reference Type";
        }
        field(5; "Knapp Station Number"; Code[3])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Knapp Station Numbers"."Station Number";
        }
        field(6; "Knapp Aisle"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec."Knapp Aisle")) > 3 then
                    Error('There should be 3 characters in the Aisle');
            end;
        }
        field(7; "Knapp Rack"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec."Knapp Rack")) > 3 then
                    Error('There should be 3 characters in the Rack');
            end;
        }
        field(8; "Knapp Rack Level"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec."Knapp Rack Level")) > 3 then
                    Error('There should be 3 characters in the Rack Level');
            end;
        }
        field(9; "Knapp Position"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec."Knapp Position")) > 3 then
                    Error('There should be 3 characters in the Position');
            end;
        }
        field(10; "Knapp Pack Size"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec."Knapp Pack Size")) > 4 then
                    Error('There should only be 4 characters in the Pack Size');
            end;
        }
        field(11; "Knapp Storage Location"; Code[12])
        {
            DataClassification = ToBeClassified;
        }
        field(12; "Knapp Ejection No"; Code[2])
        {
            DataClassification = ToBeClassified;
        }
        field(13; "Maximum ACS Quantity"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                L_KnappStations: Record "Knapp Station Numbers";
            begin
                if StrLen(Format(Rec."Maximum ACS Quantity")) > 4 then
                    Error('There should only be 4 characters in the Maximum ACS Quantity');
                L_KnappStations.Reset();
                L_KnappStations.SetRange("Station Number", Rec."Knapp Station Number");
                if L_KnappStations.FindFirst() then begin
                    if L_KnappStations.Type = L_KnappStations.Type::"Manual Station" then
                        Error('You can not enter Maximum ACS Quantity for Manual Station');
                end;
            end;
        }
        field(14; "Knapp Maximum Stock"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec."Knapp Maximum Stock")) > 4 then
                    Error('There should only be 4 characters in the Maximum Stock');
            end;
        }
        field(15; "Knapp Minimum Stock"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec."Knapp Minimum Stock")) > 4 then
                    Error('There should only be 4 characters in the Minimum Stock');
            end;
        }
        field(16; "Overstock Storage Location"; Code[12])
        {
            DataClassification = ToBeClassified;
        }
        field(17; "Item Variant Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Reference"."Variant Code";
        }
        field(18; "Priority"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Item Variant".Priority where("Item No." = field("Item No."), Code = field("Item Variant Code")));

        }
    }

    keys
    {
        key(PK; "Entry No.", "Item No.", "Item Reference No.", "Item Reference Type", "Item Variant Code")
        {

        }
    }

    trigger OnModify()
    var
        L_ItemReference: Record "Item Reference";
    begin
        L_ItemReference.Reset();
        L_ItemReference.SetRange("Item No.", Rec."Item No.");
        L_ItemReference.SetRange("Reference Type", Rec."Item Reference Type");
        L_ItemReference.SetRange("Reference No.", Rec."Item Reference No.");
        if Rec."Item Variant Code" <> '' then
            L_ItemReference.SetRange("Variant Code", Rec."Item Variant Code");
        if L_ItemReference.FindFirst() then begin
            L_ItemReference."Sent to Knapp" := false;
            L_ItemReference.Modify();
        end;
    end;

    trigger OnInsert()
    var
        L_ItemReference: Record "Item Reference";
    begin
        L_ItemReference.Reset();
        L_ItemReference.SetRange("Item No.", Rec."Item No.");
        L_ItemReference.SetRange("Reference Type", Rec."Item Reference Type");
        L_ItemReference.SetRange("Reference No.", Rec."Item Reference No.");
        if Rec."Item Variant Code" <> '' then
            L_ItemReference.SetRange("Variant Code", Rec."Item Variant Code");
        if L_ItemReference.FindFirst() then begin
            L_ItemReference."Sent to Knapp" := false;
            L_ItemReference.Modify();
        end;
    end;

    trigger OnDelete()
    var
        L_KnappItemDimensions: Record "Knapp Item Dimensions";
    begin
        L_KnappItemDimensions.Reset();
        L_KnappItemDimensions.SetRange("Item No.", Rec."Item No.");
        L_KnappItemDimensions.SetRange("Item Reference Type", Rec."Item Reference Type");
        L_KnappItemDimensions.SetRange("Item Reference No.", Rec."Item Reference No.");
        L_KnappItemDimensions.SetRange("Item Variant Code", Rec."Item Variant Code");
        L_KnappItemDimensions.SetFilter("Pack Size", '%1', Rec."Knapp Pack Size");
        if L_KnappItemDimensions.FindFirst() then
            L_KnappItemDimensions.Delete(true);
    end;
}