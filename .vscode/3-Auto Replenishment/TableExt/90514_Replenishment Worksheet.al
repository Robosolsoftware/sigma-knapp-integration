tableextension 90514 "KNP Replenishment Worksheet" extends "Replenishment Worksheet"
{
    fields
    {
        // Add changes to table fields here
        modify("Variant Code")
        {
            trigger OnAfterValidate()
            var
                L_Availabletotake: Decimal;
                L_BinContent: Record "Bin Content";
                L_ReplenishmentReport: Report "Cal _Bin Replenishment New";
                CodeUnit_ReplenishmentWorksheet: Codeunit "Replenishment Worksheet";
                TransferLineQty: Decimal;
                L_ReplenishmentWorksheet: Record "Replenishment Worksheet";
                ExistQty: Decimal;
            begin
                if Rec."Qty to Move" <> 0 then begin
                    Rec.TestField("From Location Code");
                    if Rec."Qty to Move" > Rec."Demand Quantity" then
                        Error('Qty. to Move should not be greater than Replenishment Qty. %1', Rec."Demand Quantity");

                    #Region Check Availibility qty++++
                    Clear(L_Availabletotake);
                    L_BinContent.Reset();
                    L_BinContent.SetRange("Location Code", Rec."From Location Code");
                    L_BinContent.SetRange("Item No.", Rec."Item No.");
                    L_BinContent.SetRange("Variant Code", Rec."Variant Code"); //From Variant Code+++
                    L_BinContent.SetFilter("Quantity (Base)", '>%1', 0);
                    //L_BinContent.SetRange("Daily Priority Exist", true);
                    if L_BinContent.FindSet() then begin
                        repeat
                            if L_ReplenishmentReport.UseForReplenishment(L_BinContent) then begin
                                L_Availabletotake := L_Availabletotake + L_BinContent.CalcQtyAvailToTakeUOM();
                            end;
                        until L_BinContent.Next() = 0;
                        if L_Availabletotake <= 0 then
                            L_Availabletotake := 0;

                        //calculate already exist qty in Replenishment worksheet++
                        Clear(ExistQty);
                        Clear(L_ReplenishmentWorksheet);
                        L_ReplenishmentWorksheet.SetRange("Item No.", Rec."Item No.");
                        L_ReplenishmentWorksheet.SetRange("Variant Code", Rec."Variant Code");
                        L_ReplenishmentWorksheet.SetRange("From Location Code", Rec."From Location Code");
                        //L_ReplenishmentWorksheet.SetRange("Posting Date", Rec."Posting Date");
                        L_ReplenishmentWorksheet.SetRange("Batch Name", Rec."Batch Name");
                        L_ReplenishmentWorksheet.SetFilter("Line No.", '<>%1', Rec."Line No.");
                        if L_ReplenishmentWorksheet.FindSet() then
                            repeat
                                ExistQty := ExistQty + L_ReplenishmentWorksheet."Qty to Move";
                            until L_ReplenishmentWorksheet.Next() = 0;
                        if ExistQty <= 0 then
                            ExistQty := 0;

                        //total Available++
                        L_Availabletotake := L_Availabletotake - ExistQty;
                        if L_Availabletotake < 0 then
                            L_Availabletotake := 0;

                        #Region Error Message++    
                        if L_Availabletotake = 0 then
                            Error('Quantity not available in Bincotent. Item: "%1", Variant: "%2", Location: "%3"', Rec."Item No.", Rec."Variant Code", Rec."From Location Code");

                        if L_Availabletotake < Rec."Qty to Move" then
                            Error('You cannot enter more than Available Qty.: "%1"', L_Availabletotake);
                        #EndRegion Error Message++ 

                    end else
                        Error('The field From Location Code contains a value (%1) that cannot be found in the related table (Bin Content).', Rec."From Location Code");
                    #EndRegion Check Availibility qty++++
                end;
            end;
        }
        modify("Qty to Move")
        {
            trigger OnAfterValidate()
            var
                L_Availabletotake: Decimal;
                L_BinContent: Record "Bin Content";
                L_ReplenishmentReport: Report "Cal _Bin Replenishment New";
                CodeUnit_ReplenishmentWorksheet: Codeunit "Replenishment Worksheet";
                TransferLineQty: Decimal;
                L_ReplenishmentWorksheet: Record "Replenishment Worksheet";
                ExistQty: Decimal;
            begin
                if Rec."Qty to Move" <> 0 then begin
                    Rec.TestField("From Location Code");
                    if L_ReplenishmentReport.GetVariantSetup(Rec."Item No.") then
                        Rec.TestField("Variant Code"); //From Variant Code+++

                    //+++
                    if Rec."Qty to Move" > Rec."Demand Quantity" then
                        Error('Qty. to Move should not be greater than Replenishment Qty. %1', Rec."Demand Quantity");

                    #Region Check Availability qty++++
                    Clear(L_Availabletotake);
                    L_BinContent.Reset();
                    L_BinContent.SetRange("Location Code", Rec."From Location Code");
                    L_BinContent.SetRange("Item No.", Rec."Item No.");
                    L_BinContent.SetRange("Variant Code", Rec."Variant Code"); //From Variant Code+++
                    L_BinContent.SetFilter("Quantity (Base)", '>%1', 0);
                    //L_BinContent.SetRange("Daily Priority Exist", true);
                    if L_BinContent.FindSet() then begin
                        repeat
                            if L_ReplenishmentReport.UseForReplenishment(L_BinContent) then begin
                                L_Availabletotake := L_Availabletotake + L_BinContent.CalcQtyAvailToTakeUOM();
                            end;
                        until L_BinContent.Next() = 0;
                        if L_Availabletotake <= 0 then
                            L_Availabletotake := 0;

                        //calculate already exist qty in Replenishment worksheet++
                        Clear(ExistQty);
                        Clear(L_ReplenishmentWorksheet);
                        L_ReplenishmentWorksheet.SetRange("Item No.", Rec."Item No.");
                        L_ReplenishmentWorksheet.SetRange("Variant Code", Rec."Variant Code");
                        L_ReplenishmentWorksheet.SetRange("From Location Code", Rec."From Location Code");
                        //L_ReplenishmentWorksheet.SetRange("Posting Date", Rec."Posting Date");
                        L_ReplenishmentWorksheet.SetRange("Batch Name", Rec."Batch Name");
                        L_ReplenishmentWorksheet.SetFilter("Line No.", '<>%1', Rec."Line No.");
                        if L_ReplenishmentWorksheet.FindSet() then
                            repeat
                                ExistQty := ExistQty + L_ReplenishmentWorksheet."Qty to Move";
                            until L_ReplenishmentWorksheet.Next() = 0;
                        if ExistQty <= 0 then
                            ExistQty := 0;

                        //total Available++
                        L_Availabletotake := L_Availabletotake - ExistQty;
                        if L_Availabletotake < 0 then
                            L_Availabletotake := 0;

                        #Region Error Message++  
                        if L_Availabletotake = 0 then
                            Error('Quantity not available in Bincotent. Item: "%1", Variant: "%2", Location: "%3"', Rec."Item No.", Rec."Variant Code", Rec."From Location Code");

                        if L_Availabletotake < Rec."Qty to Move" then
                            Error('You cannot enter more than Available Qty.: "%1"', L_Availabletotake);
                        #EndRegion Error Message++  
                    end else
                        Error('The field From Location Code contains a value (%1) that cannot be found in the related table (Bin Content).', Rec."From Location Code");
                    #EndRegion Check Availability qty++++
                end;
            end;
        }
        modify("Location Code")
        {
            trigger OnAfterValidate()
            var
                L_BinContent: Record "Bin Content";
                L_Availabletotake: Decimal;
                L_ReplenishmentReport: Report "Cal _Bin Replenishment New";
                CodeUnit_ReplenishmentWorksheet: Codeunit "Replenishment Worksheet";
                TransferLineQty: Decimal;
                L_ReplenishmentWorksheet: Record "Replenishment Worksheet";
                ExistQty: Decimal;
            begin
                if Rec."From Location Code" <> xRec."From Location Code" then begin
                    Rec."Qty to Move" := 0;
                    Rec."Variant Code" := ''; //From Variant+++

                    #Region Check Availibility qty++++
                    Clear(L_Availabletotake);
                    L_BinContent.Reset();
                    L_BinContent.SetRange("Location Code", Rec."From Location Code");
                    L_BinContent.SetRange("Item No.", Rec."Item No.");
                    L_BinContent.SetFilter("Quantity (Base)", '>%1', 0);
                    //L_BinContent.SetRange("Daily Priority Exist", true);
                    if L_BinContent.FindSet() then begin
                        repeat
                            if L_ReplenishmentReport.UseForReplenishment(L_BinContent) then begin
                                L_Availabletotake := L_Availabletotake + L_BinContent.CalcQtyAvailToTakeUOM();
                            end;
                        until L_BinContent.Next() = 0;
                        if L_Availabletotake <= 0 then
                            L_Availabletotake := 0;

                        //calculate already exist qty in Replenishment worksheet++
                        Clear(ExistQty);
                        Clear(L_ReplenishmentWorksheet);
                        L_ReplenishmentWorksheet.SetRange("Item No.", Rec."Item No.");
                        L_ReplenishmentWorksheet.SetRange("Variant Code", Rec."Variant Code");
                        L_ReplenishmentWorksheet.SetRange("From Location Code", Rec."From Location Code");
                        // L_ReplenishmentWorksheet.SetRange("Posting Date", Rec."Posting Date");
                        L_ReplenishmentWorksheet.SetRange("Batch Name", Rec."Batch Name");
                        L_ReplenishmentWorksheet.SetFilter("Line No.", '<>%1', Rec."Line No.");
                        if L_ReplenishmentWorksheet.FindSet() then
                            repeat
                                ExistQty := ExistQty + L_ReplenishmentWorksheet."Qty to Move";
                            until L_ReplenishmentWorksheet.Next() = 0;
                        if ExistQty <= 0 then
                            ExistQty := 0;

                        //total Available++
                        L_Availabletotake := L_Availabletotake - ExistQty;
                        if L_Availabletotake < 0 then
                            L_Availabletotake := 0;

                        #Region Error Message++
                        if L_Availabletotake = 0 then
                            Error('Quantity not available in Bincotent. Item: "%1", Variant: "%2", Location: "%3"', Rec."Item No.", Rec."Variant Code", Rec."From Location Code");

                        if L_Availabletotake < Rec."Qty to Move" then
                            Error('You cannot enter more than Available Qty.: "%1"', L_Availabletotake);
                        #EndRegion Error Message++

                    end else
                        Error('The field From Location Code contains a value (%1) that cannot be found in the related table (Bin Content).', Rec."From Location Code");
                    #EndRegion Check Availibility qty++++

                end;
            end;
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