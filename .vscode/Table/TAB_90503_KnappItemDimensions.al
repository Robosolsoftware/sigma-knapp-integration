table 90503 "Knapp Item Dimensions"
{
    DataClassification = ToBeClassified;

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
        field(5; Length; Decimal)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec.Length)) > 4 then
                    Error('There should only be 4 characters in the Length');
            end;
        }
        field(6; Width; Decimal)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec.Width)) > 4 then
                    Error('There should only be 4 characters in the Width');
            end;
        }
        field(7; Height; Decimal)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec.Height)) > 4 then
                    Error('There should only be 4 characters in the Height');
            end;
        }
        field(8; Weight; Decimal)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec.Weight)) > 6 then
                    Error('There should only be 6 characters in the Weight');
            end;
        }
        field(9; "Pack Size"; Integer)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
            begin
                if StrLen(Format(Rec."Pack Size")) > 4 then
                    Error('There should only be 4 characters in the Pack Size');
            end;
        }
        field(10; "Item Variant Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Item Reference"."Variant Code";
        }
    }
    keys
    {
        key(PK; "Entry No.", "Item No.", "Item Reference No.", "Item Reference Type", "Item Variant Code")
        {
            Clustered = true;
        }
    }

    trigger OnModify()
    var
        L_ItemReference: Record "Item Reference";
        L_KnappItemDetails: Record "Knapp Item Details";
        L_KnappItemDimensions: Record "Knapp Item Dimensions";
    begin
        L_KnappItemDetails.Reset();
        L_KnappItemDetails.SetRange("Item No.", Rec."Item No.");
        L_KnappItemDetails.SetRange("Item Reference Type", Rec."Item Reference Type");
        L_KnappItemDetails.SetRange("Item Reference No.", Rec."Item Reference No.");
        L_KnappItemDetails.SetRange("Item Variant Code", Rec."Item Variant Code");
        L_KnappItemDetails.SetFilter("Knapp Pack Size", '%1', Rec."Pack Size");
        if not L_KnappItemDetails.FindFirst() then
            Error('You can not enter knapp dimension details for the pack size ' + Format(Rec."Pack Size"));

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
        L_KnappItemDetails: Record "Knapp Item Details";
        L_KnappItemDimensions: Record "Knapp Item Dimensions";
        L_ItemReference: Record "Item Reference";
    begin
        L_KnappItemDetails.Reset();
        L_KnappItemDetails.SetRange("Item No.", Rec."Item No.");
        L_KnappItemDetails.SetRange("Item Reference Type", Rec."Item Reference Type");
        L_KnappItemDetails.SetRange("Item Reference No.", Rec."Item Reference No.");
        L_KnappItemDetails.SetRange("Item Variant Code", Rec."Item Variant Code");
        L_KnappItemDetails.SetFilter("Knapp Pack Size", '%1', Rec."Pack Size");
        if not L_KnappItemDetails.FindFirst() then
            Error('You can not enter knapp dimension details for the pack size ' + Format(Rec."Pack Size"));

        L_KnappItemDimensions.Reset();
        L_KnappItemDimensions.SetRange("Item No.", Rec."Item No.");
        L_KnappItemDimensions.SetRange("Item Reference Type", Rec."Item Reference Type");
        L_KnappItemDimensions.SetRange("Item Reference No.", Rec."Item Reference No.");
        L_KnappItemDimensions.SetRange("Item Variant Code", Rec."Item Variant Code");
        L_KnappItemDimensions.SetFilter("Pack Size", '%1', Rec."Pack Size");
        if L_KnappItemDimensions.FindFirst() then
            Error('Dimension already existed for Pack Size ' + Format(Rec."Pack Size"));

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
}