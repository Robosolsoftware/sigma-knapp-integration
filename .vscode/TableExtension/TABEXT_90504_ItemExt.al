tableextension 90504 "Item Ext" extends Item
{
    fields
    {
        field(90500; "Knapp Item"; Boolean)
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                L_ItemReference: Record "Item Reference";
            begin
                L_ItemReference.Reset();
                L_ItemReference.SetRange("Item No.", Rec."No.");
                L_ItemReference.SetFilter("Reference Type", '%1', L_ItemReference."Reference Type"::"Article Number");
                if L_ItemReference.FindSet() then begin
                    repeat
                        L_ItemReference.Validate(Knapp, Rec."Knapp Item");
                        L_ItemReference.Modify(true);
                    until L_ItemReference.Next() = 0;
                end;
            end;
        }
        field(90501; "Knapp Threshold Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(90502; "Knapp Handled"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        modify(Status)
        {
            trigger OnBeforeValidate()
            var
            begin
                if Rec.Status = Rec.Status::Released then begin
                    if Rec."Knapp Item" = true then begin
                        Rec.TestField("Knapp Threshold Quantity");
                    end;
                End;
            end;
        }
    }
}