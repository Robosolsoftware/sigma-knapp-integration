pageextension 90505 "Customer Card Ext" extends "Customer Card"
{
    layout
    {
        #Region SBB-36+++
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                if Rec.Type = Rec.Type::Site then
                    L_CustomerPriceEditable := false
                else
                    L_CustomerPriceEditable := true;
                CurrPage.Update();
            end;
        }

        addafter(Statistics)
        {
            group("BDT Team")
            {
                Editable = G_BDTTeam;
                field("Min Order Value"; Rec."Min Order Value")
                {
                    ApplicationArea = All;
                }
                field("Territory Code"; Rec."Territory Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field("Shop Group"; Rec."Shop Group")
                {
                    ApplicationArea = All;
                }
                field("Market Code"; Rec."Market Code")
                {
                    ApplicationArea = All;
                }
                field("Customer Price Group 2"; Rec."Customer Price Group 2")
                {
                    ApplicationArea = All;
                    Editable = L_CustomerPriceEditable;
                }
                field("Customer Price Group 3"; Rec."Customer Price Group 3")
                {
                    ApplicationArea = All;
                    Editable = L_CustomerPriceEditable;
                }
                field("Customer Price Group 4"; Rec."Customer Price Group 4")
                {
                    ApplicationArea = All;
                    Editable = L_CustomerPriceEditable;
                }
                field("Customer Price Group 5"; Rec."Customer Price Group 5")
                {
                    ApplicationArea = All;
                    Editable = L_CustomerPriceEditable;
                }
                field("Customer Price Group 6"; Rec."Customer Price Group 6")
                {
                    ApplicationArea = All;
                    Editable = L_CustomerPriceEditable;
                }
                field("Customer Price Group 7"; Rec."Customer Price Group 7")
                {
                    ApplicationArea = All;
                    Editable = L_CustomerPriceEditable;
                }
                field("Customer Price Group 8"; Rec."Customer Price Group 8")
                {
                    ApplicationArea = All;
                    Editable = L_CustomerPriceEditable;
                }
                field("Customer Price Group 9"; Rec."Customer Price Group 9")
                {
                    ApplicationArea = All;
                    Editable = L_CustomerPriceEditable;
                }
                field("Customer Price Group 10"; Rec."Customer Price Group 10")
                {
                    ApplicationArea = All;
                    Editable = L_CustomerPriceEditable;
                }
                field(Segment; Rec.Segment)
                {
                    ApplicationArea = All;
                }

                group("Knapp Details")
                {
                    ShowCaption = true;
                    field("Knapp Customer"; Rec."Knapp Customer")
                    {
                        ApplicationArea = All;
                    }
                    field("Knapp Special Check"; Rec."Knapp Special Check")
                    {
                        ApplicationArea = All;
                    }
                    field("Knapp Final Check"; Rec."Knapp Final Check")
                    {
                        ApplicationArea = All;
                    }
                    field("Knapp Invoice Station"; Rec."Knapp Invoice Station")
                    {
                        ApplicationArea = All;
                    }
                    field("Knapp Repack"; Rec."Knapp Repack")
                    {
                        ApplicationArea = All;
                    }
                    field("Knapp Lid"; Rec."Knapp Lid")
                    {
                        ApplicationArea = All;
                    }
                    field("Sent to Knapp"; Rec."Sent to Knapp")
                    {
                        ApplicationArea = All;
                        Editable = false;
                    }
                }
            }
        }
        modify("Customer Price Group")
        {
            Caption = 'Customer Price Group 1';
            Editable = L_CustomerPriceEditable;
        }

        moveafter("Market Code"; "Customer Price Group")
        #EndRegion SBB-36+++


        modify(Name)
        {
            ShowMandatory = true;
        }
    }

    trigger OnAfterGetRecord()
    var
        L_UserSetup: Record "User Setup";
    begin
        Clear(L_CurrPageEditable);
        Clear(G_BDTTeam);


        if Rec.Type = Rec.Type::Site then
            L_CustomerPriceEditable := false
        else
            L_CustomerPriceEditable := true;

        L_UserSetup.Reset();
        L_UserSetup.SetRange("User ID", UserId);
        if L_UserSetup.FindFirst() then begin
            if L_UserSetup."BDT Team Permission" = true then
                G_BDTTeam := true
            else
                G_BDTTeam := false;
        end else
            G_BDTTeam := false;



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
        Clear(G_BDTTeam);

        if Rec.Type = Rec.Type::Site then
            L_CustomerPriceEditable := false
        else
            L_CustomerPriceEditable := true;

        L_UserSetup.Reset();
        L_UserSetup.SetRange("User ID", UserId);
        if L_UserSetup.FindFirst() then begin
            if L_UserSetup."BDT Team Permission" = true then
                G_BDTTeam := true
            else
                G_BDTTeam := false;
        end else
            G_BDTTeam := false;


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

    trigger OnClosePage()
    var
    begin
        if Rec.Name = '' then
            Error('Customer Name is required');
    end;

    var
        L_CurrPageEditable: Boolean;
        G_BDTTeam: Boolean;
        L_CustomerPriceEditable: Boolean;
}