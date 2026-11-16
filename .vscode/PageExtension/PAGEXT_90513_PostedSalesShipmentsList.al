pageextension 90513 "Posted Sales Shipments Ext." extends "Posted Sales Shipments"
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("Knapp Customer"; Rec."Knapp Customer")
            {
                ApplicationArea = ALl;
                Editable = false;
            }
            field("Order No."; Rec."Order No.")
            {
                ApplicationArea = ALl;
                Editable = false;
            }
            field("No of Boxes"; Rec."No of Boxes")
            {
                ApplicationArea = ALl;
                Editable = false;
            }
            field("No. of Totes"; GetTotalTote(Rec))
            {
                ApplicationArea = ALl;
                Editable = false;
            }
        }
    }

    procedure GetTotalTote(_Rec: Record "Sales Shipment Header"): Integer
    var
        L_KnappOrderResponse: Record "Knapp Order Response";
        L_LodUnit: Code[100];
        L_TotalLoadUnit: Integer;
    begin
        Clear(L_LodUnit);
        Clear(L_TotalLoadUnit);

        L_KnappOrderResponse.Reset();
        L_KnappOrderResponse.SetRange("Document Type", L_KnappOrderResponse."Document Type"::Order);
        L_KnappOrderResponse.SetRange("Document No.", _Rec."Order No.");
        L_KnappOrderResponse.SetCurrentKey("Load Unit");
        L_KnappOrderResponse.Ascending(true);
        if L_KnappOrderResponse.FindSet() then begin
            repeat
                if L_LodUnit <> L_KnappOrderResponse."Load Unit" then
                    L_TotalLoadUnit := L_TotalLoadUnit + 1;

                L_LodUnit := L_KnappOrderResponse."Load Unit";
            until L_KnappOrderResponse.Next() = 0;
        end;

        exit(L_TotalLoadUnit);
    end;

}

