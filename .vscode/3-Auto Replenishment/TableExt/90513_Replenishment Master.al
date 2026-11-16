tableextension 90513 "KNP Replenishment Master" extends "Replenishment Master"
{
    fields
    {
        // Add changes to table fields here
        field(90513; "KNAPP Item"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = Lookup(Item."Knapp Item" where("No." = field("Item No.")));
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}