pageextension 90512 "Sales Order Subform Ext." extends "Sales Order Subform"
{
    layout
    {
        modify(Quantity)
        {
            Editable = not Rec."Sent to Knapp";
        }
        // modify("Qty. to Ship")
        // {
        //     Enabled = G_EditQtyShip;
        // }
        modify("Qty. to Ship")
        {
            trigger OnAfterValidate()
            var
                L_SalesHeader: Record "Sales Header";
                UserSetup: Record "User Setup";
            begin
                L_SalesHeader.Reset();
                L_SalesHeader.SetRange("Document Type", Rec."Document Type");
                L_SalesHeader.SetRange("No.", Rec."Document No.");
                if L_SalesHeader.FindFirst() then begin
                    if L_SalesHeader."Knapp Order" = true then begin
                        UserSetup.Reset();
                        if UserSetup.Get(UserId) then begin
                            if UserSetup."Update Qty. to Ship" = false then begin
                                Error('You cannot change the quantity if the KNAPP order is true.');
                            end;
                        end
                        else
                            Error('You cannot change the quantity if the KNAPP order is true.');
                    end;
                end;
            end;
        }
        // modify("Variant Code")
        // {
        //     Enabled = G_EditQtyShip;
        // }
        addafter(Description)
        {
            field("Knapp Item"; Rec."Knapp Item")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Knapp Line"; Rec."Knapp Line")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Sent to Knapp"; Rec."Sent to Knapp")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Sheet Number"; Rec."Sheet Number")
            {
                ApplicationArea = All;
                Editable = true;
            }
            field("Load Unit"; Rec."Load Unit")
            {
                ApplicationArea = All;
                Editable = true;
            }
        }
        // modify("Qty. to Ship")
        // {
        //     Editable = not Rec."Knapp Line";
        // }
        addlast(Control1)
        {
            field(Remarks; Rec.Remarks)
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }
    actions
    {
        addafter("Reservation Entries")
        {
            action("Knapp Order Response")
            {
                ApplicationArea = Basic, Suite;
                Image = ViewDetails;
                RunObject = Page "Knapp Order Responses";
                RunPageLink = "Document Type" = field("Document Type"), "Document No." = field("Document No.");
            }
        }
    }

    var
        G_EditQtyShip: Boolean;


    // trigger OnAfterGetRecord()
    // var
    //     L_SalesHeader: Record "Sales Header";
    // begin
    //     L_SalesHeader.Reset();
    //     L_SalesHeader.SetRange("Document Type", Rec."Document Type");
    //     L_SalesHeader.SetRange("No.", Rec."Document No.");
    //     if L_SalesHeader.FindFirst() then begin
    //         if L_SalesHeader."Knapp Order" = true then begin
    //             G_EditQtyShip := false;
    //         end else
    //             G_EditQtyShip := true;
    //     end;
    // end;
}