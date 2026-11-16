page 90504 "Knapp Article Details"
{
    PageType = ListPart;
    UsageCategory = Administration;
    SourceTable = "Knapp Item Details";

    layout
    {
        area(Content)
        {
            repeater("Article Details")
            {
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Item Reference Type"; Rec."Item Reference Type")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Knapp Station Number"; Rec."Knapp Station Number")
                {
                    ApplicationArea = All;
                    Caption = 'Station Number';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        KnappStationNumbers: Record "Knapp Station Numbers";
                    begin
                        if Page.RunModal(90502, KnappStationNumbers) = ACTION::LookUpOk then
                            Rec."Knapp Station Number" := KnappStationNumbers."Station Number";
                    end;
                }
                field("Knapp Aisle"; Rec."Knapp Aisle")
                {
                    ApplicationArea = All;
                    Caption = 'Aisle';
                }
                field("Knapp Rack"; Rec."Knapp Rack")
                {
                    ApplicationArea = All;
                    Caption = 'Rack';
                }
                field("Knapp Rack Level"; Rec."Knapp Rack Level")
                {
                    ApplicationArea = All;
                    Caption = 'Rack Level';
                }
                field("Knapp Position"; Rec."Knapp Position")
                {
                    ApplicationArea = All;
                    Caption = 'Position';
                }
                field("Knapp Pack Size"; Rec."Knapp Pack Size")
                {
                    ApplicationArea = All;
                    Caption = 'Pack Size';
                }
                field("Knapp Storage Location"; Rec."Knapp Storage Location")
                {
                    ApplicationArea = All;
                    Caption = 'Storage Location';
                }
                field("Knapp Ejection No"; Rec."Knapp Ejection No")
                {
                    ApplicationArea = All;
                    Caption = 'Ejection No';
                }
                field("Maximum ACS Quantity"; Rec."Maximum ACS Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Maximum ACS Quantity';
                }
                field("Knapp Maximum Stock"; Rec."Knapp Maximum Stock")
                {
                    ApplicationArea = All;
                    Caption = 'Maximum Stock';
                }
                field("Knapp Minimum Stock"; Rec."Knapp Minimum Stock")
                {
                    ApplicationArea = All;
                    Caption = 'Minimum Stock';
                }
                field("Overstock Storage Location"; Rec."Overstock Storage Location")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}