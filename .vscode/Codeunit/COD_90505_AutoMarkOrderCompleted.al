codeunit 90505 "Auto Mark Order Completed"
{
    trigger OnRun()
    var
        L_SalesHeader: Record "Sales Header";
        L_KnappPicking: Record "Knapp Picking Details";
        L_TotalCount: Integer;
        LineCount: Integer;
    begin
        L_SalesHeader.Reset();
        L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
        L_SalesHeader.SetRange("Knapp Order", true);
        L_SalesHeader.SetRange("Sent to Knapp", true);
        L_SalesHeader.SetRange(Shipped, false);
        L_SalesHeader.SetRange("Knapp Response Available", true);
        L_SalesHeader.SetRange("Order Complete", false);
        if L_SalesHeader.FindSet() then begin
            repeat
                Clear(L_TotalCount);
                Clear(LineCount);
                L_KnappPicking.Reset();
                L_KnappPicking.SetRange("Document Type", L_KnappPicking."Document Type"::Order);
                L_KnappPicking.SetRange("Document No.", L_SalesHeader."No.");
                L_KnappPicking.SetRange("Knapp Response Exist", true);
                if L_KnappPicking.FindSet() then
                    L_TotalCount := L_KnappPicking.Count;

                L_KnappPicking.Reset();
                L_KnappPicking.SetRange("Document Type", L_KnappPicking."Document Type"::Order);
                L_KnappPicking.SetRange("Document No.", L_SalesHeader."No.");
                //L_KnappPicking.SetRange("Knapp Response Exist", false);
                if L_KnappPicking.FindSet() then
                    LineCount := L_KnappPicking.Count;

                if LineCount = L_TotalCount then begin
                    L_SalesHeader.Validate("Order Complete", true);
                    L_SalesHeader.Modify();
                end;
            until L_SalesHeader.Next() = 0;
        end;
    end;
}