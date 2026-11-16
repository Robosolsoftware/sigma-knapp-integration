pageextension 90504 "Shipping Agent Services Ext" extends "Shipping Agent Services"
{
    layout
    {
        addafter(Description)
        {
            field(Shift; Rec.Shift)
            {
                ApplicationArea = All;
                Editable = L_CurrPageEditable;
            }
            field("Departure Time"; Rec."Departure Time")
            {
                ApplicationArea = All;
                Editable = L_CurrPageEditable;
            }
        }
        addafter(CustomizedCalendar)
        {
            field("Knapp Round"; Rec."Knapp Round")
            {
                ApplicationArea = All;
                Editable = L_CurrPageEditable;
            }
            field("Sent to Knapp"; Rec."Sent to Knapp")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
        modify("Base Calendar Code")
        {
            Visible = false;
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