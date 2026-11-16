page 90513 "Custom Cue"
{
    PageType = CardPart;
    RefreshOnActivate = true;
    Caption = 'Order Status Visibility';
    layout
    {
        area(Content)
        {
            cuegroup(General)
            {
                ShowCaption = false;
                field(AwaitingManualPick; AwaitingManualPick)
                {
                    ApplicationArea = All;
                    Caption = 'Awaiting Manual Pick';
                    trigger OnDrillDown()
                    var
                        SOList: Page "Sales Order List";
                        SalesHeader: Record "Sales Header";
                    begin
                        Clear(SOList);
                        SalesHeader.Reset();
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
                        SalesHeader.CalcFields("Inv. Pick Exist", Shipped);
                        SalesHeader.SetRange(Shipped, false);
                        SalesHeader.SetRange("Inv. Pick Exist", false);
                        SalesHeader.SetRange("Knapp Order", false);
                        if SalesHeader.FindSet() then begin
                            SOList.SetTableView(SalesHeader);
                            SOList.Run();
                        end;
                    end;
                }
                field(AwaitingKnappSubmit; AwaitingKnappSubmit)
                {
                    ApplicationArea = All;
                    Caption = 'Awaiting KNAPP Submit';
                    trigger OnDrillDown()
                    var
                        SOList: Page "Sales Order List";
                        SalesHeader: Record "Sales Header";
                    begin
                        Clear(SOList);
                        SalesHeader.Reset();
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
                        SalesHeader.SetRange("Location Code", 'KNAPP');
                        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp");
                        SalesHeader.SetRange("Sent to Knapp", false);
                        SalesHeader.SetRange("Knapp Order", true);
                        if SalesHeader.FindSet() then begin
                            SOList.SetTableView(SalesHeader);
                            SOList.Run();
                        end;
                    end;
                }
                field(ManualPickInprogress; ManualPickInprogress)
                {
                    ApplicationArea = All;
                    Caption = 'Manual Pick In-progress';
                    trigger OnDrillDown()
                    var
                        SOList: Page "Sales Order List";
                        SalesHeader: Record "Sales Header";
                    begin
                        Clear(SOList);
                        SalesHeader.Reset();
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
                        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp");
                        SalesHeader.SetRange("Inv. Pick Exist", true);
                        SalesHeader.SetRange("Knapp Order", false);
                        if SalesHeader.FindSet() then begin
                            SOList.SetTableView(SalesHeader);
                            SOList.Run();
                        end;
                    end;
                }
                field(KnappPickInprogress; KnappPickInprogress)
                {
                    ApplicationArea = All;
                    Caption = 'KNAPP Pick In-progress';
                    trigger OnDrillDown()
                    var
                        SOList: Page "Sales Order List";
                        SalesHeader: Record "Sales Header";
                    begin
                        Clear(SOList);
                        SalesHeader.Reset();
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
                        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp");
                        SalesHeader.SetRange("Sent to Knapp", true);
                        SalesHeader.SetRange("Order Complete", false);
                        SalesHeader.SetRange("Knapp Order", true);
                        if SalesHeader.FindSet() then begin
                            SOList.SetTableView(SalesHeader);
                            SOList.Run();
                        end;
                    end;
                }
                field(NonKnappOrdersPending; NonKnappOrdersPending)
                {
                    ApplicationArea = All;
                    Caption = 'Non-Knapp Orders Pending Invoice';
                    trigger OnDrillDown()
                    var
                        SOList: Page "Sales Order List";
                        SalesHeader: Record "Sales Header";
                    begin
                        Clear(SOList);
                        SalesHeader.Reset();
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
                        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp", "Shipped Not Invoiced");
                        SalesHeader.SetRange("Shipped Not Invoiced", true);
                        SalesHeader.SetRange("Knapp Order", false);
                        if SalesHeader.FindSet() then begin
                            SOList.SetTableView(SalesHeader);
                            SOList.Run();
                        end;
                    end;
                }
                field(KnappOrdersPending; KnappOrdersPending)
                {
                    ApplicationArea = All;
                    Caption = 'KNAPP Orders Pending Invoices';
                    trigger OnDrillDown()
                    var
                        SOList: Page "Sales Order List";
                        SalesHeader: Record "Sales Header";
                    begin
                        Clear(SOList);
                        SalesHeader.Reset();
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
                        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp", "Knapp Response Available", "Knapp Response with Picks");
                        SalesHeader.SetRange("Knapp Response Available", true);
                        SalesHeader.SetRange("Knapp Response with Picks", true);
                        SalesHeader.SetRange("Knapp Order", true);
                        SalesHeader.SetRange("Order Complete", true);
                        SalesHeader.SetRange("Sent to Knapp", true);
                        SalesHeader.SetRange(Shipped, false);
                        if SalesHeader.FindSet() then begin
                            SOList.SetTableView(SalesHeader);
                            SOList.Run();
                        end;
                    end;
                }
                field(PartialInvoiceGenerated; PartialInvoiceGenerated)
                {
                    ApplicationArea = All;
                    Caption = 'Partial Invoice Generated (KNAPP & Non-KNAPP)';
                    trigger OnDrillDown()
                    var
                        SOList: Page "Sales Order List";
                        SalesHeader: Record "Sales Header";
                    begin
                        Clear(SOList);
                        SalesHeader.Reset();
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
                        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp");
                        SalesHeader.SetRange(Shipped, true);
                        if SalesHeader.FindSet() then begin
                            SOList.SetTableView(SalesHeader);
                            SOList.Run();
                        end;
                    end;
                }
            }
        }
    }
    trigger OnOpenPage()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Awaiting Manual Pick
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.CalcFields("Inv. Pick Exist", Shipped);
        SalesHeader.SetRange(Shipped, false);
        SalesHeader.SetRange("Inv. Pick Exist", false);
        SalesHeader.SetRange("Knapp Order", false);
        AwaitingManualPick := SalesHeader.Count();

        // Awaiting KNAPP Submit
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetRange("Location Code", 'KNAPP');
        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp");
        SalesHeader.SetRange("Sent to Knapp", false);
        SalesHeader.SetRange("Knapp Order", true);
        AwaitingKnappSubmit := SalesHeader.Count();

        // Manual Pick In-progress
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp");
        SalesHeader.SetRange("Inv. Pick Exist", true);
        SalesHeader.SetRange("Knapp Order", false);
        ManualPickInprogress := SalesHeader.Count();

        // KNAPP Pick In-progress
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp");
        SalesHeader.SetRange("Sent to Knapp", true);
        SalesHeader.SetRange("Order Complete", false);
        SalesHeader.SetRange("Knapp Order", true);
        KnappPickInprogress := SalesHeader.Count();

        // Non-Knapp Orders Pending Invoice
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp", "Shipped Not Invoiced");
        SalesHeader.SetRange("Shipped Not Invoiced", true);
        SalesHeader.SetRange("Knapp Order", false);
        NonKnappOrdersPending := SalesHeader.Count();

        // KNAPP Orders Pending Invoices
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp", "Knapp Response Available", "Knapp Response with Picks");
        SalesHeader.SetRange("Knapp Response Available", true);
        SalesHeader.SetRange("Knapp Response with Picks", true);
        SalesHeader.SetRange("Knapp Order", true);
        SalesHeader.SetRange("Order Complete", true);
        SalesHeader.SetRange("Sent to Knapp", true);
        SalesHeader.SetRange(Shipped, false);
        KnappOrdersPending := SalesHeader.Count();

        // Partial Invoice Generated (KNAPP & Non-KNAPP)
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.CalcFields("Inv. Pick Exist", Shipped, "Sent to Knapp");
        SalesHeader.SetRange(Shipped, true);
        PartialInvoiceGenerated := SalesHeader.Count();
    end;

    var
        AwaitingManualPick: Integer;
        AwaitingKnappSubmit: Integer;
        ManualPickInprogress: Integer;
        KnappPickInprogress: Integer;
        NonKnappOrdersPending: Integer;
        KnappOrdersPending: Integer;
        PartialInvoiceGenerated: Integer;

}