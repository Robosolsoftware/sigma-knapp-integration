tableextension 90500 "Item Reference Ext" extends "Item Reference"
{
    DataCaptionFields = "Item No.", "Reference No.";

    fields
    {
        field(90500; Knapp; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90501; "Sent to Knapp"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        modify("Reference No.")
        {
            trigger OnBeforeValidate()
            var
            begin
                if Rec."Reference Type" = Rec."Reference Type"::"Article Number" then
                    if StrLen(Rec."Reference No.") > 14 then
                        Error('For the Article Number Reference type, the reference number should consist of just 14 characters.');
            end;
        }
        modify("Reference Type")
        {
            trigger OnBeforeValidate()
            var
                L_Item: Record Item;
            begin
                if (Rec."Item No." <> '') and (Rec."Reference Type" = Rec."Reference Type"::"Article Number") then begin
                    L_Item.Reset();
                    if L_Item.Get(Rec."Item No.") then begin
                        if L_Item."Knapp Item" = false then
                            Error('The item does not belong to Knapp, so you cannot enter the Article Number for it');
                    end;
                end;
            end;
        }
        modify("Variant Code")
        {
            trigger OnBeforeValidate()
            var
                L_KnappItemDetails: Record "Knapp Item Details";
                L_KnappItemDimension: Record "Knapp Item Dimensions";
            begin
                if xRec."Variant Code" <> '' then begin
                    L_KnappItemDetails.Reset();
                    L_KnappItemDetails.SetRange("Item No.", Rec."Item No.");
                    L_KnappItemDetails.SetRange("Item Reference No.", Rec."Reference No.");
                    L_KnappItemDetails.SetRange("Item Reference Type", L_KnappItemDetails."Item Reference Type"::"Article Number");
                    L_KnappItemDetails.SetRange("Item Variant Code", xRec."Variant Code");
                    if L_KnappItemDetails.FindFirst() then begin
                        Error('You can not change the existing Variant Code because it has Article details against it.');
                    end
                    else begin
                        L_KnappItemDetails.Reset();
                        L_KnappItemDetails.SetRange("Item No.", Rec."Item No.");
                        L_KnappItemDetails.SetRange("Item Reference No.", Rec."Reference No.");
                        L_KnappItemDetails.SetRange("Item Reference Type", L_KnappItemDetails."Item Reference Type"::"Article Number");
                        if L_KnappItemDetails.FindSet() then begin
                            repeat
                                L_KnappItemDetails.Rename(L_KnappItemDetails."Entry No.", L_KnappItemDetails."Item No.", L_KnappItemDetails."Item Reference No.", L_KnappItemDetails."Item Reference Type", Rec."Variant Code");
                                if L_KnappItemDetails."Item Reference Type" <> L_KnappItemDetails."Item Reference Type"::"Article Number" then
                                    error('Item Reference Type should be Article Number.')
                            until L_KnappItemDetails.Next() = 0;
                        end;

                        L_KnappItemDimension.Reset();
                        L_KnappItemDimension.SetRange("Item No.", Rec."Item No.");
                        L_KnappItemDimension.SetRange("Item Reference No.", Rec."Reference No.");
                        L_KnappItemDimension.SetRange("Item Reference Type", L_KnappItemDimension."Item Reference Type"::"Article Number");
                        if L_KnappItemDimension.FindSet() then begin
                            repeat
                                L_KnappItemDimension.Rename(L_KnappItemDimension."Entry No.", L_KnappItemDimension."Item No.", L_KnappItemDimension."Item Reference No.", L_KnappItemDimension."Item Reference Type", Rec."Variant Code");
                                if L_KnappItemDimension."Item Reference Type" <> L_KnappItemDimension."Item Reference Type"::"Article Number" then
                                    error('Item Reference Type should be Article Number')
                            until L_KnappItemDimension.Next() = 0;
                        end;
                    end;
                end
                else begin
                    L_KnappItemDetails.Reset();
                    L_KnappItemDetails.SetRange("Item No.", Rec."Item No.");
                    L_KnappItemDetails.SetRange("Item Reference No.", Rec."Reference No.");
                    L_KnappItemDetails.SetRange("Item Reference Type", L_KnappItemDetails."Item Reference Type"::"Article Number");
                    if L_KnappItemDetails.FindSet() then begin
                        repeat
                            L_KnappItemDetails.Rename(L_KnappItemDetails."Entry No.", L_KnappItemDetails."Item No.", L_KnappItemDetails."Item Reference No.", L_KnappItemDetails."Item Reference Type", Rec."Variant Code");
                            if L_KnappItemDetails."Item Reference Type" <> L_KnappItemDetails."Item Reference Type"::"Article Number" then
                                error('Item Reference Type should be Article Number')
                        until L_KnappItemDetails.Next() = 0;
                    end;

                    L_KnappItemDimension.Reset();
                    L_KnappItemDimension.SetRange("Item No.", Rec."Item No.");
                    L_KnappItemDimension.SetRange("Item Reference No.", Rec."Reference No.");
                    L_KnappItemDimension.SetRange("Item Reference Type", L_KnappItemDimension."Item Reference Type"::"Article Number");
                    if L_KnappItemDimension.FindSet() then begin
                        repeat
                            L_KnappItemDimension.Rename(L_KnappItemDimension."Entry No.", L_KnappItemDimension."Item No.", L_KnappItemDimension."Item Reference No.", L_KnappItemDimension."Item Reference Type", Rec."Variant Code");
                            if L_KnappItemDimension."Item Reference Type" <> L_KnappItemDimension."Item Reference Type"::"Article Number" then
                                error('Item Reference Type should be Article Number')
                        until L_KnappItemDimension.Next() = 0;
                    end;
                end;
            end;
        }
    }

    trigger OnInsert()
    var
        L_Item: Record Item;
    begin
        if (Rec."Item No." <> '') and (Rec."Reference Type" = Rec."Reference Type"::"Article Number") then begin
            if StrLen(Rec."Reference No.") > 14 then
                Error('For the Article Number Reference type, the reference number should consist of just 14 characters.');

            L_Item.Reset();
            if L_Item.Get(Rec."Item No.") then begin
                if L_Item."Knapp Item" = false then
                    Error('The item does not belong to Knapp, so you cannot enter the Article Number for it');
                Rec.Knapp := L_Item."Knapp Item";
            end;
        end;
    end;

    trigger OnModify()
    var
    begin
        Rec."Sent to Knapp" := false;
    end;

    trigger OnDelete()
    var
        L_KnappItemDetails: Record "Knapp Item Details";
    begin
        if Rec."Reference Type" = Rec."Reference Type"::"Article Number" then begin
            L_KnappItemDetails.Reset();
            L_KnappItemDetails.SetRange("Item No.", Rec."Item No.");
            L_KnappItemDetails.SetRange("Item Reference No.", Rec."Reference No.");
            L_KnappItemDetails.SetRange("Item Reference Type", L_KnappItemDetails."Item Reference Type"::"Article Number");
            L_KnappItemDetails.SetRange("Item Variant Code", Rec."Variant Code");
            if L_KnappItemDetails.FindFirst() then
                Error('You can not delete this Article Number as there are Article Details available against it.');
        end;
    end;
}