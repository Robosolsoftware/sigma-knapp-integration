tableextension 90508 "Sales Line Ext." extends "Sales Line"
{
    fields
    {

        field(90500; "Knapp Item"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90501; "Sent to Knapp"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90502; "Knapp Line"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90503; Remarks; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(90504; "Sheet Number"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(90505; "Load Unit"; Code[8])
        {
            DataClassification = ToBeClassified;
        }
        field(90506; "Knapp Qty. to Ship"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("Knapp Order Response".Quantity where("Document Type" = field("Document Type"), "Document No." = field("Document No."), "Item No." = field("No."), "Line No." = field("Line No.")));
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                L_Item: Record Item;
                L_Location: Record Location;
                CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
            begin
                if (Rec.Type = Rec.Type::Item) then begin
                    L_Item.Reset();
                    L_Item.SetRange("No.", Rec."No.");
                    if L_Item.FindFirst() then begin
                        Rec."Knapp Item" := L_Item."Knapp Item";
                    end;
                end;
            end;
        }

        modify(Quantity)
        {
            trigger OnAfterValidate()
            var
                L_Item: Record Item;
                L_SalesHeader: Record "Sales Header";
                IsRouteKnapp: Boolean;
                IsItemKnapp: Boolean;
                KnappThresholdQuantity: Decimal;
                L_ShippingAgentService: Record "Shipping Agent Services";
            begin
                L_SalesHeader.Reset();
                L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
                L_SalesHeader.SetRange("No.", Rec."Document No.");
                if L_SalesHeader.FindFirst() then begin
                    L_ShippingAgentService.Reset();
                    L_ShippingAgentService.SetRange("Shipping Agent Code", L_SalesHeader."Shipping Agent Code");
                    if L_SalesHeader."Weekend Ship. Agnt. Serv. Code" <> '' then
                        L_ShippingAgentService.SetRange(Code, L_SalesHeader."Weekend Ship. Agnt. Serv. Code")
                    else
                        L_ShippingAgentService.SetRange(Code, L_SalesHeader."Shipping Agent Service Code");
                    if L_ShippingAgentService.FindFirst() then
                        IsRouteKnapp := L_ShippingAgentService."Knapp Round";

                    Clear(KnappThresholdQuantity);
                    L_Item.Reset();
                    L_Item.SetRange("No.", Rec."No.");
                    if L_Item.FindFirst() then begin
                        IsItemKnapp := L_Item."Knapp Item";
                        KnappThresholdQuantity := L_Item."Knapp Threshold Quantity";
                    end;

                    if (L_SalesHeader."Knapp Customer" = true) and (IsRouteKnapp = true) and (IsItemKnapp = true) then begin
                        if KnappThresholdQuantity <> 0 then begin
                            if Rec.Quantity <= KnappThresholdQuantity then begin
                                Rec.Validate("Knapp Line", true);
                                if L_SalesHeader."IRP Order" = true then
                                    Rec.Validate("Qty. to Ship", 0);
                            end
                            else begin
                                Rec.Validate("Knapp Line", false);
                            end;
                        end else begin
                            Rec.Validate("Knapp Line", true);
                            if L_SalesHeader."IRP Order" = true then
                                Rec.Validate("Qty. to Ship", 0);
                        end;
                    end;
                end;
            end;
        }
    }

    trigger OnInsert()
    var
        L_SalesHeader: Record "Sales Header";
    begin
        L_SalesHeader.Reset();
        L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
        L_SalesHeader.SetRange("No.", Rec."Document No.");
        L_SalesHeader.SetRange("Check & Split Order", false);
        if L_SalesHeader.FindFirst() then begin
            if (L_SalesHeader."Knapp Order" = true) and (L_SalesHeader."IRP Order" = false) then
                Error('You can not add a new line to this order as it has been converted into a Knapp order');
        end;
    end;
}