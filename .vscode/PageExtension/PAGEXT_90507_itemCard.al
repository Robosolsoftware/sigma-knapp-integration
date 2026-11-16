pageextension 90507 "Item Card Ext" extends "Item Card"
{
    layout
    {
        addlast(Replenishment)
        {
            field("Knapp Item"; Rec."Knapp Item")
            {
                ApplicationArea = All;
                Editable = L_CurrPageEditable;
            }
            field("Knapp Threshold Quantity"; Rec."Knapp Threshold Quantity")
            {
                ApplicationArea = All;
                Editable = L_CurrPageEditable;
                ShowMandatory = true;
            }
            field("Knapp Handled"; Rec."Knapp Handled")
            {
                ApplicationArea = All;
                Editable = L_CurrPageEditable;
                //ShowMandatory = true;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        L_UserSetup: Record "User Setup";
    begin
        Clear(L_CurrPageEditable);
        if Rec.Status = Rec.Status::Open then begin
            L_CurrPageEditable := true;
        end else begin
            L_UserSetup.Reset();
            L_UserSetup.SetRange("User ID", UserId);
            if L_UserSetup.FindFirst() then begin
                if L_UserSetup."Edit Master Data" = true then begin
                    if Rec.Status = Rec.Status::Open then
                        L_CurrPageEditable := true
                    else
                        L_CurrPageEditable := false;
                end else
                    L_CurrPageEditable := false;
            end else
                L_CurrPageEditable := false;
        end;
    end;

    trigger OnOpenPage()
    var
        L_UserSetup: Record "User Setup";
    begin
        Clear(L_CurrPageEditable);
        if Rec.Status = Rec.Status::Open then begin
            L_CurrPageEditable := true;
        end else begin
            L_UserSetup.Reset();
            L_UserSetup.SetRange("User ID", UserId);
            if L_UserSetup.FindFirst() then begin
                if L_UserSetup."Edit Master Data" = true then begin
                    if Rec.Status = Rec.Status::Open then
                        L_CurrPageEditable := true
                    else
                        L_CurrPageEditable := false;
                end else
                    L_CurrPageEditable := false;
            end else
                L_CurrPageEditable := false;
        end;
    end;

    var
        L_CurrPageEditable: Boolean;
}