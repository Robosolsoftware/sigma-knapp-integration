pageextension 90501 "Item Reference List Ext" extends "Item Reference List"
{
    layout
    {
        addlast(Control1)
        {
            field(Knapp; Rec.Knapp)
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Sent to Knapp"; Rec."Sent to Knapp")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
        moveafter(Description; "Description 2")
        modify("Description 2")
        {
            ApplicationArea = All;
            Caption = 'Article Description';
            Visible = true;
        }
        modify("Starting Date")
        {
            Visible = false;
        }
        modify("Ending Date")
        {
            Visible = false;
        }
    }
    actions
    {
        addafter(PrintLabel)
        {
            action("Knapp Article Details")
            {
                ApplicationArea = Basic, Suite;
                Image = ViewDetails;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                //RunObject = Page "Knapp Article/Dimensions";
                //RunPageLink = "Item No." = field("Item No."), "Reference No." = field("Reference No."), "Reference Type" = field("Reference Type");

                trigger OnAction()
                var
                    KnappArticleDimensions: Page "Knapp Article/Dimensions";
                    ItemReference: Record "Item Reference";
                begin
                    if Rec."Reference Type" <> Rec."Reference Type"::"Article Number" then
                        Error('You can not enter knapp specific details for this record');
                    ItemReference.SetRange("Item No.", Rec."Item No.");
                    ItemReference.SetRange("Reference No.", rec."Reference No.");
                    ItemReference.SetFilter("Reference Type", '%1', ItemReference."Reference Type"::"Article Number");
                    ItemReference.SetFilter("Variant Code", '%1', Rec."Variant Code");
                    if ItemReference.FindFirst() then begin
                        Clear(KnappArticleDimensions);
                        KnappArticleDimensions.SetRecord(ItemReference);
                        KnappArticleDimensions.Run();
                    end;
                end;
            }
            action("Upadate Knapp Details")
            {
                ApplicationArea = Basic, Suite;
                Image = UpdateDescription;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Visible = false;

                trigger OnAction()
                var
                begin
                    Codeunit.Run(90504);
                end;
            }
        }
    }
}