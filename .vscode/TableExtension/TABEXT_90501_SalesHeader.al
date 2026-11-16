tableextension 90501 "Sales Header Ext." extends "Sales Header"
{
    fields
    {
        field(90500; "Knapp Customer"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90501; "Knapp Order"; Boolean)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
            begin
                if (Rec."Knapp Order" = false) and (Rec."Posting No." <> '') and ("IRP Order" = false) then
                    Error('You can not make this order a non-Knapp Order as it has Posting No. against it');
            end;
        }
        field(90502; "Sent Knapp Invoice"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90503; "Knapp Invoice Remark"; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(90504; "Sent to Knapp"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Sales Line" where("Document Type" = const(Order), "Document No." = field("No."), "Sent to Knapp" = const(true)));
        }
        field(90505; "Knapp Response Available"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Knapp Order Response" where("Document Type" = const(Order), "Document No." = field("No."), Quantity = filter(> 0)));
        }
        field(90506; "Order Complete"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(90507; "Knapp Response with Picks"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Knapp Order Response" where("Document Type" = const(Order), "Document No." = field("No.")));
        }
        modify("Sell-to Customer No.")
        {
            trigger OnAfterValidate()
            var
                L_Customer: Record Customer;
            begin
                if Rec."Sell-to Customer No." <> '' then begin
                    L_Customer.Reset();
                    L_Customer.SetRange("No.", Rec."Sell-to Customer No.");
                    if L_Customer.FindFirst() then begin
                        if Rec."IRP Order" = false then begin
                            L_Customer.TestField("QAU Approved");
                            L_Customer.TestField(Status, L_Customer.Status::Released);
                        end;
                        Rec."Knapp Customer" := L_Customer."Knapp Customer";
                    end;
                end;
            end;
        }
        modify("Sell-to Customer Name")
        {
            trigger OnAfterValidate()
            var
                L_Customer: Record Customer;
            begin
                if Rec."Sell-to Customer Name" <> '' then begin
                    L_Customer.Reset();
                    L_Customer.SetRange("No.", Rec."Sell-to Customer No.");
                    if L_Customer.FindFirst() then begin
                        if Rec."IRP Order" = false then begin
                            L_Customer.TestField("QAU Approved");
                            L_Customer.TestField(Status, L_Customer.Status::Released);
                        end;
                        Rec."Knapp Customer" := L_Customer."Knapp Customer";
                    end;
                end;
            end;
        }
    }

    procedure CreateInvtPutAwayPick_Copy()
    var
        WhseRequest: Record "Warehouse Request";
    begin
        if "Document Type" = "Document Type"::Order then
            if not IsApprovedForPosting() then
                exit;

        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        case "Document Type" of
            "Document Type"::Order:
                begin
                    if "Shipping Advice" = "Shipping Advice"::Complete then
                        CheckShippingAdvice();
                    WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Order");
                end;
            "Document Type"::"Return Order":
                WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Return Order");
        end;
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt. Pick", true, false, WhseRequest);
    end;
}