pageextension 90526 "KNP Replenishment Worksheet" extends "Replenishment Worksheet"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addfirst(Processing)
        {
            action("Calculate Bin &Replenishment")
            {
                ApplicationArea = all;
                Caption = 'Calculate Bin &Replenishment';
                Ellipsis = true;
                Image = CalculateBinReplenishment;

                trigger OnAction()
                var
                    Location: Record Location;
                    ReplenishBinContent: Report "Cal _Bin Replenishment New";
                begin
                    Commit();
                    Location.Get('DEPOT1');
                    ReplenishBinContent.InitializeRequest(Rec."Template Name", Rec."Batch Name", Location.Code, false);
                    ReplenishBinContent.Run();
                    Clear(ReplenishBinContent);
                end;
            }
            action(Register)
            {
                ApplicationArea = all;
                Image = Register;

                trigger OnAction()
                var
                    L_ReplenishmentWorksheet: Record "Replenishment Worksheet";
                    L_ReplenishmentWorksheetCode: Codeunit "Replenishment Worksheet";
                begin
                    #Region For Top Category Items only+++
                    L_ReplenishmentWorksheet.Reset();
                    CurrPage.SetSelectionFilter(L_ReplenishmentWorksheet);
                    L_ReplenishmentWorksheet.SetRange(Action, L_ReplenishmentWorksheet.Action::Accept);
                    //L_ReplenishmentWorksheet.SetRange("Top Category", true);
                    L_ReplenishmentWorksheet.SetFilter("Top Category", '<>%1', L_ReplenishmentWorksheet."Top Category"::" ");
                    L_ReplenishmentWorksheet.SetRange("Batch Name", Rec."Batch Name");
                    L_ReplenishmentWorksheet.SetFilter("Qty to Move", '>%1', 0);
                    if L_ReplenishmentWorksheet.FindSet() then begin
                        if L_ReplenishmentWorksheetCode.CreateTransferOrder(L_ReplenishmentWorksheet, 'SH') then begin
                            L_ReplenishmentWorksheet.DeleteAll();
                        end;
                    end;
                    #EndRegion For Top Category Items only+++

                    #Region For Non Top Category Items only+++
                    L_ReplenishmentWorksheet.Reset();
                    CurrPage.SetSelectionFilter(L_ReplenishmentWorksheet);
                    L_ReplenishmentWorksheet.SetRange(Action, L_ReplenishmentWorksheet.Action::Accept);
                    //L_ReplenishmentWorksheet.SetRange("Top Category", false);
                    L_ReplenishmentWorksheet.SetFilter("Top Category", '%1', L_ReplenishmentWorksheet."Top Category"::" ");
                    L_ReplenishmentWorksheet.SetRange("Batch Name", Rec."Batch Name");
                    L_ReplenishmentWorksheet.SetFilter("Qty to Move", '>%1', 0);
                    if L_ReplenishmentWorksheet.FindSet() then begin
                        if L_ReplenishmentWorksheetCode.CreateTransferOrder(L_ReplenishmentWorksheet, 'HDH') then begin
                            L_ReplenishmentWorksheet.DeleteAll();
                        end;
                    end;
                    #EndRegion For Non Top Category Items only+++

                    #Region For Unit1 Items Only+++
                    //Requirement not cleared
                    #EndRegion For Unit1 Items Only+++

                    //Final Message++
                    Message('Process completed..');
                end;
            }
        }
    }

    var
        myInt: Integer;
}