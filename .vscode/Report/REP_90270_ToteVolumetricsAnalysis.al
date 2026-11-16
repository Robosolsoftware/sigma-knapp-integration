// // =============================================================================
// Report  : Tote Volumetrics Analysis
// Purpose : Analyse the number of Totes required per Customer / Shipping Agent
//           Service Code based on a Shipment Date filter.
//           - Source    : Released Sales Orders (Sales Header + Sales Line)
//                         Posted Sales Invoices (Sales Invoice Header + Line)
//           - Dimensions: Knapp Item Dimensions table (Length / Width / Height mm)
//           - Tote size : configurable (default 505 x 335 x 198 mm)
// Columns : Type | Customer No. | Customer Name | Shipping Agent Code |
//           Shipping Agent Service Code | Shipment Date | No. of Totes
// =============================================================================
report 90501 "Tote Volumetrics Analysis"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Tote Volumetrics Analysis';
    DefaultLayout = RDLC;
    RDLCLayout = './REP_90270_ToteVolumetricsAnalysis.rdl';
    dataset
    {
        // -----------------------------------------------------------------------
        // Data item 1: Released Sales Orders
        // -----------------------------------------------------------------------
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = WHERE(
                "Document Type" = CONST(Order),
                Status = CONST(Released));
            RequestFilterFields = "Shipment Date", "Shipping Agent Code", "Shipping Agent Service Code", "Location Code";
            // -- Header-level columns ------------------------------------------
            column(SalesHeaderNo; "Sales Header"."No.") { }
            column(CustomerNo; "Sales Header"."Sell-to Customer No.") { }
            column(CustomerName; "Sales Header"."Sell-to Customer Name") { }
            column(ShippingAgentCode; "Sales Header"."Shipping Agent Code") { }
            column(ShippingAgentServiceCode; "Sales Header"."Shipping Agent Service Code") { }
            column(ShipmentDate; "Sales Header"."Shipment Date") { }
            // Calculated columns surfaced to the RDLC layout
            column(TotalOrderVolumeMM3; TotalOrderVolumeMM3) { }
            column(NumberOfTotes; NumberOfTotes) { }
            column(ToteCapacityMM3; ToteCapacityMM3) { }
            // Record type identifier
            column(RecordType; RecordType) { }
            // -- Company info for report header --------------------------------
            column(CompanyName; CompanyInfo.Name) { }
            column(CompanyAddress; CompanyInfo.Address) { }
            column(CompanyLogo; CompanyInfo.Picture) { }
            column(PrintedBy; UserId()) { }
            column(PrintedDate; Today()) { }
            column(Percentage; Percentage)
            {
                DecimalPlaces = 0 : 5;
            }
            column(ToteLength_MM; ToteLength_MM) { }
            column(ToteWidth_MM; ToteWidth_MM) { }
            column(ToteHeight_MM; ToteHeight_MM) { }
            column(ToteCapacityLbl; ToteCapacityLbl) { }
            column(TotalVolumeLbl; TotalVolumeLbl) { }
            trigger OnAfterGetRecord()
            var
                L_SalesLine: Record "Sales Line";
                L_ItemReference: Record "Item Reference";
                L_KnappItemDim: Record "Knapp Item Dimensions";
                L_PacksOnLine: Decimal;
                L_LineVolumeMM3: Decimal;
                L_ItemVolumeMM3: Decimal;
            begin
                ToteCapacityLbl := StrSubstNo('Tote Capacity (mm³)(%1 %)', FillRate);
                // Tag this record as an Order
                RecordType := RecordTypeOrderTxt;
                // Initialise accumulators for this Sales Order
                TotalOrderVolumeMM3 := 0;
                NumberOfTotes := 0;
                L_SalesLine.Reset();
                L_SalesLine.SetRange("Document Type", "Sales Header"."Document Type");
                L_SalesLine.SetRange("Document No.", "Sales Header"."No.");
                L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                L_SalesLine.SetFilter("Outstanding Quantity", '>%1', 0);
                if L_SalesLine.FindSet() then
                    repeat
                        L_ItemReference.Reset();
                        L_ItemReference.SetRange("Item No.", L_SalesLine."No.");
                        L_ItemReference.SetRange("Reference Type", L_ItemReference."Reference Type"::"Article Number");
                        if L_SalesLine."Variant Code" <> '' then
                            L_ItemReference.SetRange("Variant Code", L_SalesLine."Variant Code");
                        if not L_ItemReference.FindFirst() then
                            // No Article Number reference — skip this line
                            L_KnappItemDim.Reset();
                        L_KnappItemDim.SetRange("Item No.", L_ItemReference."Item No.");
                        L_KnappItemDim.SetRange("Item Reference No.", L_ItemReference."Reference No.");
                        L_KnappItemDim.SetRange("Item Reference Type", L_ItemReference."Reference Type");
                        if L_SalesLine."Variant Code" <> '' then
                            L_KnappItemDim.SetRange("Item Variant Code", L_SalesLine."Variant Code");
                        L_KnappItemDim.SetRange("Pack Size", 1);
                        if not L_KnappItemDim.FindFirst() then begin
                            L_KnappItemDim.SetRange("Pack Size");
                            L_KnappItemDim.SetCurrentKey("Item No.", "Item Reference No.", "Item Reference Type", "Pack Size");
                            L_KnappItemDim.Ascending(true);
                            if not L_KnappItemDim.FindFirst() then;
                        end;
                        if (L_KnappItemDim.Length = 0) or
                           (L_KnappItemDim.Width = 0) or
                           (L_KnappItemDim.Height = 0) then;
                        L_ItemVolumeMM3 := L_KnappItemDim.Length *
                                            L_KnappItemDim.Width *
                                            L_KnappItemDim.Height;
                        L_PacksOnLine := L_SalesLine."Outstanding Quantity";
                        L_LineVolumeMM3 := L_ItemVolumeMM3 * L_PacksOnLine;
                        TotalOrderVolumeMM3 += L_LineVolumeMM3;
                    until L_SalesLine.Next() = 0;
                ToteCapacityMM3 := ((ToteLength_MM * ToteWidth_MM * ToteHeight_MM) * FillRate) / 100;
                Percentage := (TotalOrderVolumeMM3 / ToteCapacityMM3) * 100;
                if TotalOrderVolumeMM3 > 0 then
                    NumberOfTotes := Round(TotalOrderVolumeMM3 / ToteCapacityMM3, 1, '>')
                else
                    NumberOfTotes := 0;
                if ShowOnlyWithTotes and (NumberOfTotes = 0) then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();


                if GetFilter("Location Code") = '' then
                    SetFilter("Location Code", 'DEPOT1|KNAPP');

            end;
        }
        // -----------------------------------------------------------------------
        // Data item 2: Posted Sales Invoices
        // -----------------------------------------------------------------------
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            // Expose the same filter fields so users can apply date / agent filters
            RequestFilterFields = "Shipment Date", "Shipping Agent Code", "Shipping Agent Service Code", "Location Code";
            // -- Header-level columns ------------------------------------------
            column(InvHeaderNo; "Sales Invoice Header"."No.") { }
            column(InvCustomerNo; "Sales Invoice Header"."Sell-to Customer No.") { }
            column(InvCustomerName; "Sales Invoice Header"."Sell-to Customer Name") { }
            column(InvShippingAgentCode; "Sales Invoice Header"."Shipping Agent Code") { }
            column(InvShippingAgentServiceCode; "Sales Invoice Header"."Shipping Agent Service Code") { }
            column(InvShipmentDate; "Sales Invoice Header"."Shipment Date") { }
            // Calculated columns
            column(InvTotalOrderVolumeMM3; TotalOrderVolumeMM3) { }
            column(InvNumberOfTotes; NumberOfTotes) { }
            column(InvToteCapacityMM3; ToteCapacityMM3) { }
            // Record type identifier
            column(InvRecordType; RecordType) { }
            column(InvPercentage; Percentage)
            {
                DecimalPlaces = 0 : 5;
            }
            trigger OnAfterGetRecord()
            var
                L_InvLine: Record "Sales Invoice Line";
                L_ItemReference: Record "Item Reference";
                L_KnappItemDim: Record "Knapp Item Dimensions";
                L_PacksOnLine: Decimal;
                L_LineVolumeMM3: Decimal;
                L_ItemVolumeMM3: Decimal;
            begin

                ToteCapacityLbl := StrSubstNo('Tote Capacity (mm³)(%1 %)', FillRate);
                // Tag this record as an Invoice
                RecordType := RecordTypeInvoiceTxt;
                // Initialise accumulators
                TotalOrderVolumeMM3 := 0;
                NumberOfTotes := 0;
                // Iterate Item lines on this Posted Sales Invoice
                L_InvLine.Reset();
                L_InvLine.SetRange("Document No.", "Sales Invoice Header"."No.");
                L_InvLine.SetRange(Type, L_InvLine.Type::Item);
                L_InvLine.SetFilter(Quantity, '>%1', 0);
                if L_InvLine.FindSet() then
                    repeat
                        // Locate the Article Number Item Reference for this item
                        L_ItemReference.Reset();
                        L_ItemReference.SetRange("Item No.", L_InvLine."No.");
                        L_ItemReference.SetRange("Reference Type", L_ItemReference."Reference Type"::"Article Number");
                        if L_InvLine."Variant Code" <> '' then
                            L_ItemReference.SetRange("Variant Code", L_InvLine."Variant Code");
                        if not L_ItemReference.FindFirst() then
                            // No Article Number reference — skip this line
                            // Get Knapp Item Dimensions for Pack Size = 1
                            L_KnappItemDim.Reset();
                        L_KnappItemDim.SetRange("Item No.", L_ItemReference."Item No.");
                        L_KnappItemDim.SetRange("Item Reference No.", L_ItemReference."Reference No.");
                        L_KnappItemDim.SetRange("Item Reference Type", L_ItemReference."Reference Type");
                        if L_InvLine."Variant Code" <> '' then
                            L_KnappItemDim.SetRange("Item Variant Code", L_InvLine."Variant Code");
                        L_KnappItemDim.SetRange("Pack Size", 1);
                        if not L_KnappItemDim.FindFirst() then begin
                            // Fallback: smallest available pack size
                            L_KnappItemDim.SetRange("Pack Size");
                            L_KnappItemDim.SetCurrentKey("Item No.", "Item Reference No.", "Item Reference Type", "Pack Size");
                            L_KnappItemDim.Ascending(true);
                            if not L_KnappItemDim.FindFirst() then;
                        end;
                        // Skip lines with missing dimensions
                        if (L_KnappItemDim.Length = 0) or
                           (L_KnappItemDim.Width = 0) or
                           (L_KnappItemDim.Height = 0) then;
                        L_ItemVolumeMM3 := L_KnappItemDim.Length *
                                            L_KnappItemDim.Width *
                                            L_KnappItemDim.Height;
                        L_PacksOnLine := L_InvLine.Quantity;
                        L_LineVolumeMM3 := L_ItemVolumeMM3 * L_PacksOnLine;
                        TotalOrderVolumeMM3 += L_LineVolumeMM3;
                    until L_InvLine.Next() = 0;
                // Calculate totes (ceiling division)
                ToteCapacityMM3 := ((ToteLength_MM * ToteWidth_MM * ToteHeight_MM) * FillRate) / 100;
                Percentage := (TotalOrderVolumeMM3 / ToteCapacityMM3) * 100;
                if TotalOrderVolumeMM3 > 0 then
                    NumberOfTotes := Round(TotalOrderVolumeMM3 / ToteCapacityMM3, 1, '>')
                else
                    NumberOfTotes := 0;
                if ShowOnlyWithTotes and (NumberOfTotes = 0) then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Location Code") = '' then
                    SetFilter("Location Code", 'DEPOT1|KNAPP');
            end;
        }
    }
    // -------------------------------------------------------------------------
    // Request Page
    // -------------------------------------------------------------------------
    requestpage
    {
        // SaveValues = true;
        layout
        {
            area(Content)
            {
                group(Filters)
                {
                    Caption = 'Filters';
                    field(FillRate; FillRate)
                    {
                        ApplicationArea = All;
                        Caption = 'Recommended Tote Filling Capacity(mm³)';
                        ToolTip = 'Percentage of tote volume to use for packing calculations. Default: 50%.';
                    }
                    field(ShowOnlyWithTotes; ShowOnlyWithTotes)
                    {
                        ApplicationArea = All;
                        Caption = 'Show Only Orders Requiring Totes';
                        ToolTip = 'When enabled, records with zero tote volume are excluded from the report.';
                    }
                }
                group(ToteParameters)
                {
                    Caption = 'Tote Parameters (mm)';
                    field(ToteLength_MM_Request; ToteLength_MM)
                    {
                        ApplicationArea = All;
                        Caption = 'Avg. Tote Length (mm)';
                        ToolTip = 'Internal length of the tote in millimetres. Default: 505 mm.';
                        MinValue = 1;
                    }
                    field(ToteWidth_MM_Request; ToteWidth_MM)
                    {
                        ApplicationArea = All;
                        Caption = 'Avg. Tote Width (mm)';
                        ToolTip = 'Internal width of the tote in millimetres. Default: 335 mm.';
                        MinValue = 1;
                    }
                    field(ToteHeight_MM_Request; ToteHeight_MM)
                    {
                        ApplicationArea = All;
                        Caption = 'Avg. Tote Height (mm)';
                        ToolTip = 'Internal height of the tote in millimetres. Default: 198 mm.';
                        MinValue = 1;
                    }
                }
            }
        }
        trigger OnOpenPage()
        begin
            if ToteLength_MM = 0 then ToteLength_MM := 505;
            if ToteWidth_MM = 0 then ToteWidth_MM := 335;
            if ToteHeight_MM = 0 then ToteHeight_MM := 198;
            if FillRate = 0 then FillRate := 50;

            "Sales Header".SetFilter("Location Code", 'DEPOT1|KNAPP');
            "Sales Invoice Header".SetFilter("Location Code", 'DEPOT1|KNAPP');

        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = CloseAction::OK then begin
                if ShipmentDateFilter = '' then
                    Error(ShipmentDateMandatoryErr);
                // Apply Shipment Date filter to both data items
                "Sales Header".SetFilter("Shipment Date", ShipmentDateFilter);
                "Sales Invoice Header".SetFilter("Shipment Date", ShipmentDateFilter);
            end;
            exit(true);
        end;
    }
    // -------------------------------------------------------------------------
    // Labels
    // -------------------------------------------------------------------------
    labels
    {
        ReportTitleLbl = 'Tote Volumetrics Analysis';
        CustomerNoLbl = 'Customer No.';
        CustomerNameLbl = 'Customer Name';
        ShippingAgentCodeLbl = 'Shipping Agent Code';
        ShippingAgentServiceCodeLbl = 'Shipping Agent Service Code';
        ShipmentDateLbl = 'Shipment Date';
        OrderNoLbl = 'Sales Order No.';
        NoOfTotesLbl = 'No. of Totes Required';
        PageLbl = 'Page';
        PrintedByLbl = 'Printed By';
        PrintedDateLbl = 'Printed Date';
        ToteDimensionsLbl = 'Tote Dimensions (L x W x H mm)';
        RecordTypeLbl = 'Type';
    }
    // -------------------------------------------------------------------------
    // Variables
    // -------------------------------------------------------------------------
    var
        CompanyInfo: Record "Company Information";
        TotalOrderVolumeMM3: Decimal;
        NumberOfTotes: Integer;
        ToteCapacityMM3: Decimal;
        ToteLength_MM: Decimal;
        ToteWidth_MM: Decimal;
        ToteHeight_MM: Decimal;
        ShipmentDateFilter: Text;
        ShowOnlyWithTotes: Boolean;
        ShipmentDateMandatoryErr: Label 'Shipment Date Filter must not be blank. Please specify a date or date range.';
        Percentage: Decimal;
        FillRate: Decimal;
        ToteCapacityLbl: Text[50];
        TotalVolumeLbl: Label 'Total Item Volume (mm³)';
        RecordType: Text[20];
        RecordTypeOrderTxt: Label 'Order', Locked = true;
        RecordTypeInvoiceTxt: Label 'Invoice', Locked = true;
}
