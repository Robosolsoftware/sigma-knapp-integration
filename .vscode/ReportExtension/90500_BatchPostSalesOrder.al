reportextension 90500 "KI Batch Post Sales Orders" extends "Batch Post Sales Orders"
{
    dataset
    {
        // Add changes to dataitems and columns here
        modify("Sales Header")
        {
            trigger OnBeforePreDataItem()
            var
                KnappEvents: Codeunit "Knapp Events";
            begin
                KnappEvents.GetOrderCategoryFilter(G_OrderCategory);
            end;
        }
    }

    requestpage
    {
        // Add changes to the requestpage here
        layout
        {
            addafter(Invoice)
            {
                field(KIOrderCategoryField; G_OrderCategory)
                {
                    Caption = 'Order Category';
                    ToolTip = 'Specifies the order category to filter the sales orders.';
                    ApplicationArea = All;
                }
            }
        }

    }

    var
        G_OrderCategory: Option "Standard Order","Knapp Order";
}