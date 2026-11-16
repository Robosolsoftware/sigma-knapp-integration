page 90512 "Add Knapp Response"
{
    PageType = StandardDialog;
    UsageCategory = Administration;
    SourceTable = "Order Filter Table";

    layout
    {
        area(Content)
        {
            group("Knapp Response")
            {
                field("Tote Number"; Rec."Tote Number")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;

                    trigger OnValidate()
                    var
                        L_KnappOrderResponse: Record "Knapp Order Response";
                        ToteNumber: Code[8];
                    begin
                        if Rec."Tote Number" = '' then
                            Error('Please enter a valid Tote Number');
                        if (StrLen(Format(Rec."Tote Number")) > 8) or (StrLen(Format(Rec."Tote Number")) < 8) then
                            Error('Tote Number should be 8 characters long');

                        Clear(ToteNumber);
                        ToteNumber := Format(Rec."Tote Number");

                        L_KnappOrderResponse.Reset();
                        L_KnappOrderResponse.SetRange("Document Type", L_KnappOrderResponse."Document Type"::Order);
                        L_KnappOrderResponse.SetRange("Document No.", Rec."Primary key");
                        L_KnappOrderResponse.SetRange("Load Unit", ToteNumber);
                        if L_KnappOrderResponse.FindFirst() then
                            Error('There is already a response available against selected "Tote Number" for this order');
                    end;
                }
                field("Sheet Number"; Rec."Sheet Number")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowMandatory = true;

                    trigger OnValidate()
                    var
                        L_KnappPickingDetails: Record "Knapp Picking Details";
                        L_KnappOrderResponse: Record "Knapp Order Response";
                    begin
                        if Rec."Sheet Number" = 0 then
                            Error('Please enter a valid Sheet Number');
                        if StrLen(Format(Rec."Sheet Number")) > 3 then
                            Error('Sheet Number should be 3 characters long');

                        L_KnappPickingDetails.Reset();
                        L_KnappPickingDetails.SetRange("Document Type", L_KnappPickingDetails."Document Type"::Order);
                        L_KnappPickingDetails.SetRange("Document No.", Rec."Primary key");
                        L_KnappPickingDetails.SetRange("Sheet Number", Rec."Sheet Number");
                        if not L_KnappPickingDetails.FindFirst() then
                            Error('You will not be able to add details for this Sheet because it was not initiated from Knapps end for this order.');

                        L_KnappOrderResponse.Reset();
                        L_KnappOrderResponse.SetRange("Document Type", L_KnappOrderResponse."Document Type"::Order);
                        L_KnappOrderResponse.SetRange("Document No.", Rec."Primary key");
                        L_KnappOrderResponse.SetRange("Sheet Number", Rec."Sheet Number");
                        if L_KnappOrderResponse.FindFirst() then
                            Error('There is already a response available against selected "Sheet Number" for this order');
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
    begin
        Clear(Rec."Tote Number");
    end;
}