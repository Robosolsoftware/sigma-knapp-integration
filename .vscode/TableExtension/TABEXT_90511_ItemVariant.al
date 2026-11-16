tableextension 90511 "Item Variant Ext." extends "Item Variant"
{
    fields
    {
        modify(Priority)
        {
            trigger OnAfterValidate()
            var
                L_Item: Record Item;
                L_ItemReference: Record "Item Reference";
                L_KnappItemDetails: Record "Knapp Item Details";
                L_KnappItemDimensions: Record "Knapp Item Dimensions";
            begin
                if Rec.Priority > 0 then begin
                    L_Item.Reset();
                    if L_Item.Get(Rec."Item No.") then begin
                        if L_Item."Knapp Item" = true then begin
                            L_ItemReference.Reset();
                            L_ItemReference.SetRange("Item No.", Rec."Item No.");
                            L_ItemReference.SetRange("Variant Code", Rec.Code);
                            L_ItemReference.SetRange("Reference Type", L_ItemReference."Reference Type"::"Article Number");
                            if not L_ItemReference.FindFirst() then
                                Error('You can not enter priority for this Variant as no Article Number Details are available for it');

                            L_KnappItemDetails.Reset();
                            L_KnappItemDetails.SetRange("Item No.", Rec."Item No.");
                            L_KnappItemDetails.SetRange("Item Variant Code", Rec.Code);
                            L_KnappItemDetails.SetRange("Item Reference Type", L_KnappItemDetails."Item Reference Type"::"Article Number");
                            if not L_KnappItemDetails.FindFirst() then
                                Error('You can not enter priority for this Variant as no Article Number Details are available for it');

                            L_KnappItemDimensions.Reset();
                            L_KnappItemDimensions.SetRange("Item No.", Rec."Item No.");
                            L_KnappItemDimensions.SetRange("Item Variant Code", Rec.Code);
                            L_KnappItemDimensions.SetRange("Item Reference Type", L_KnappItemDimensions."Item Reference Type"::"Article Number");
                            if not L_KnappItemDimensions.FindFirst() then
                                Error('You can not enter priority for this Variant as no Article Number Dimensions are available for it');
                        end;
                    end;
                end;
            end;
        }
    }
}