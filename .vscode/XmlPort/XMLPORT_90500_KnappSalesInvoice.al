xmlport 90500 "Knapp Sales Invoice"
{
    Caption = 'Knapp Sales Invoice';
    Format = Xml;
    Direction = Export;
    UseRequestPage = true;
    Encoding = UTF8;

    schema
    {
        textelement(RootNodeName)
        {
            tableelement(SalesHeader; "Sales Header")
            {
                XmlName = 'SalesHeader';
                RequestFilterFields = "No.";
                SourceTableView = where("Document Type" = const(order));
                CalcFields = "Amount Including VAT", Amount;
                fieldelement(OrderNo; SalesHeader."No.")
                {
                }
                fieldelement(InvoiceNo; SalesHeader."Posting No.")
                {
                }
                fieldelement(CustomerOrderNo; SalesHeader."External Document No.")
                {

                }
                fieldelement(BilltoCustomerNo; SalesHeader."Bill-to Customer No.")
                {
                }
                fieldelement(BilltoCustomerName; SalesHeader."Bill-to Name")
                {
                }
                fieldelement(BilltoAddress; SalesHeader."Bill-to Address")
                {
                }
                fieldelement(BilltoAddress2; SalesHeader."Bill-to Address 2")
                {
                }
                fieldelement(BilltoCity; SalesHeader."Bill-to City")
                {
                }
                fieldelement(BilltoCounty; SalesHeader."Bill-to County")
                {
                }
                fieldelement(BilltoCountryRegionCode; SalesHeader."Bill-to Country/Region Code")
                {
                }
                fieldelement(BilltoPostCode; SalesHeader."Bill-to Post Code")
                {
                }
                fieldelement(LocationCode; SalesHeader."Location Code")
                {
                }
                fieldelement(ShiptoCode; SalesHeader."Ship-to Code")
                {
                }
                fieldelement(ShiptoName; SalesHeader."Ship-to Name")
                {
                }
                fieldelement(ShiptoAddress; SalesHeader."Ship-to Address")
                {
                }
                fieldelement(ShiptoAddress2; SalesHeader."Ship-to Address 2")
                {
                }
                fieldelement(ShiptoCity; SalesHeader."Ship-to City")
                {
                }
                fieldelement(ShiptoCounty; SalesHeader."Ship-to County")
                {
                }
                fieldelement(ShiptoCountryRegionCode; SalesHeader."Ship-to Country/Region Code")
                {
                }
                fieldelement(ShiptoPostCode; SalesHeader."Ship-to Post Code")
                {
                }
                textelement(AmountIncludingVAT)
                {
                    trigger OnBeforePassVariable()
                    var
                        TotalAmountIncVAT: Decimal;
                    begin
                        Clear(TotalAmountIncVAT);
                        G_KnappOrderResponse.Reset();
                        G_KnappOrderResponse.SetRange("Document Type", G_KnappOrderResponse."Document Type"::Order);
                        G_KnappOrderResponse.SetRange("Document No.", SalesHeader."No.");
                        G_KnappOrderResponse.SetFilter(Quantity, '>0');
                        if G_KnappOrderResponse.FindSet() then begin
                            repeat
                                TotalAmountIncVAT += G_KnappOrderResponse."Amount Including VAT";
                            until G_KnappOrderResponse.Next() = 0;
                        end;
                        AmountIncludingVAT := Format(TotalAmountIncVAT);
                    end;
                }
                textelement(Amount)
                {
                    trigger OnBeforePassVariable()
                    var
                        TotalAmount: Decimal;
                    begin
                        Clear(TotalAmount);
                        G_KnappOrderResponse.Reset();
                        G_KnappOrderResponse.SetRange("Document Type", G_KnappOrderResponse."Document Type"::Order);
                        G_KnappOrderResponse.SetRange("Document No.", SalesHeader."No.");
                        G_KnappOrderResponse.SetFilter(Quantity, '>0');
                        if G_KnappOrderResponse.FindSet() then begin
                            repeat
                                TotalAmount += G_KnappOrderResponse.Amount;
                            until G_KnappOrderResponse.Next() = 0;
                        end;
                        Amount := Format(TotalAmount);
                    end;
                }
                textelement(VATAmount)
                {
                    trigger OnBeforePassVariable()
                    var
                        L_VATAmount: Decimal;
                    begin
                        //VATAmount := Format(SalesHeader."Amount Including VAT" - SalesHeader.Amount);
                        Clear(L_VATAmount);
                        G_KnappOrderResponse.Reset();
                        G_KnappOrderResponse.SetRange("Document Type", G_KnappOrderResponse."Document Type"::Order);
                        G_KnappOrderResponse.SetRange("Document No.", SalesHeader."No.");
                        G_KnappOrderResponse.SetFilter(Quantity, '>0');
                        if G_KnappOrderResponse.FindSet() then begin
                            repeat
                                L_VATAmount += G_KnappOrderResponse."VAT Amount";
                            until G_KnappOrderResponse.Next() = 0;
                        end;
                        VATAmount := Format(L_VATAmount);
                    end;
                }
                textelement(ShippingAgentCode)
                {
                    trigger OnBeforePassVariable()
                    var
                    begin
                        if SalesHeader."Weekend Shipping Agent Code" <> '' then
                            ShippingAgentCode := SalesHeader."Weekend Shipping Agent Code"
                        else
                            ShippingAgentCode := SalesHeader."Shipping Agent Code";
                    end;
                }
                textelement(ShippingAgentServiceCode)
                {
                    trigger OnBeforePassVariable()
                    var
                    begin
                        if SalesHeader."Weekend Ship. Agnt. Serv. Code" <> '' then
                            ShippingAgentServiceCode := SalesHeader."Weekend Ship. Agnt. Serv. Code"
                        else
                            ShippingAgentServiceCode := SalesHeader."Shipping Agent Service Code";
                    end;
                }
                textelement(DocumentDate)
                {
                    trigger OnBeforePassVariable()
                    var
                    begin
                        if WorkDate() > SalesHeader."Shipment Date" then begin
                            DocumentDate := Format(WorkDate(), 0, '<Day,2>/<Month,2>/<Year4>');
                        end else begin
                            DocumentDate := Format(SalesHeader."Shipment Date", 0, '<Day,2>/<Month,2>/<Year4>');
                        end;
                    end;
                }
                fieldelement(BilltoCustomerNo; SalesHeader."Bill-to Customer No.")
                {
                }
                textelement(CustTele)
                {
                    trigger OnBeforePassVariable()
                    var
                        Customer: Record Customer;
                    begin
                        Clear(CustTele);
                        Customer.Reset();
                        Customer.SetRange("No.", SalesHeader."Bill-to Customer No.");
                        if Customer.FindFirst() then begin
                            CustTele := Customer."Phone No.";
                        end else begin
                            CustTele := SalesHeader."sell-to Phone No.";
                        end;
                    end;
                }
                textelement(ShipTele)
                {
                    trigger OnBeforePassVariable()
                    var
                        ShiptoAddress: Record "Ship-to Address";
                    begin
                        Clear(ShipTele);
                        if SalesHeader."Ship-to Code" = '' then begin
                            ShipTele := SalesHeader."Sell-to Phone No.";
                        end else begin
                            ShiptoAddress.Reset();
                            ShiptoAddress.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
                            ShiptoAddress.SetRange(Code, SalesHeader."Ship-to Code");
                            if ShiptoAddress.FindFirst() then begin
                                ShipTele := ShiptoAddress."Phone No.";
                            end;
                        end;
                    end;
                }
                textelement(BankName)
                {
                    trigger OnBeforePassVariable()
                    var
                        Customer: Record Customer;
                        BankAccount: Record "Bank Account";
                    begin
                        Clear(BankName);
                        Customer.Reset();
                        Customer.SetRange("No.", SalesHeader."Sell-to Customer No.");
                        if Customer.FindFirst() then begin
                            if Customer."Default Bank" <> '' then begin
                                BankAccount.Reset();
                                BankAccount.SetRange("No.", Customer."Default Bank");
                                if BankAccount.FindFirst() then
                                    BankName := CopyStr(BankAccount.Name, 1, 25);
                            end;
                        end;
                    end;
                }
                textelement(BankBranchNo)
                {
                    trigger OnBeforePassVariable()
                    var
                        Customer: Record Customer;
                        BankAccount: Record "Bank Account";
                    begin
                        Clear(BankBranchNo);
                        Customer.Reset();
                        Customer.SetRange("No.", SalesHeader."Sell-to Customer No.");
                        if Customer.FindFirst() then begin
                            if Customer."Default Bank" <> '' then begin
                                BankAccount.Reset();
                                BankAccount.SetRange("No.", Customer."Default Bank");
                                if BankAccount.FindFirst() then
                                    BankBranchNo := CopyStr(BankAccount."Bank Branch No.", 1, 7);
                            end;
                        end;
                    end;
                }
                textelement(BankAccountNo)
                {
                    trigger OnBeforePassVariable()
                    var
                        Customer: Record Customer;
                        BankAccount: Record "Bank Account";
                    begin
                        Clear(BankAccountNo);
                        Customer.Reset();
                        Customer.SetRange("No.", SalesHeader."Sell-to Customer No.");
                        if Customer.FindFirst() then begin
                            if Customer."Default Bank" <> '' then begin
                                BankAccount.Reset();
                                BankAccount.SetRange("No.", Customer."Default Bank");
                                if BankAccount.FindFirst() then
                                    BankAccountNo := CopyStr(BankAccount."Bank Account No.", 1, 8);
                            end;
                        end;
                    end;
                }
                textelement(SWIFTCode)
                {
                    trigger OnBeforePassVariable()
                    var
                        Customer: Record Customer;
                        BankAccount: Record "Bank Account";
                    begin
                        Clear(SWIFTCode);
                        Customer.Reset();
                        Customer.SetRange("No.", SalesHeader."Sell-to Customer No.");
                        if Customer.FindFirst() then begin
                            if Customer."Default Bank" <> '' then begin
                                BankAccount.Reset();
                                BankAccount.SetRange("No.", Customer."Default Bank");
                                if BankAccount.FindFirst() then
                                    SWIFTCode := CopyStr(BankAccount."SWIFT Code", 1, 7);
                            end;
                        end;
                    end;
                }
                textelement(IBAN)
                {
                    trigger OnBeforePassVariable()
                    var
                        Customer: Record Customer;
                        BankAccount: Record "Bank Account";
                    begin
                        Clear(IBAN);
                        Customer.Reset();
                        Customer.SetRange("No.", SalesHeader."Sell-to Customer No.");
                        if Customer.FindFirst() then begin
                            if Customer."Default Bank" <> '' then begin
                                BankAccount.Reset();
                                BankAccount.SetRange("No.", Customer."Default Bank");
                                if BankAccount.FindFirst() then
                                    IBAN := CopyStr(BankAccount.IBAN, 1, 25);
                            end;
                        end;
                    end;
                }
                tableelement("SalesLine"; "Knapp Order Response")
                {
                    LinkTable = "SalesHeader";
                    LinkFields = "Document No." = field("No."), "Document Type" = field("Document Type");

                    fieldelement(LineNo; SalesLine."Line No.")
                    {
                    }
                    textelement(Description)
                    {
                        trigger OnBeforePassVariable()
                        var
                        begin
                            Clear(Description);
                            Description := CopyStr(SalesLine.Description, 1, 30);
                        end;
                    }
                    fieldelement(No; SalesLine."Item No.")
                    {
                    }
                    fieldelement(Quantity; SalesLine.Quantity)
                    {
                    }
                    fieldelement(UnitPrice; SalesLine."Unit Price")
                    {
                    }
                    fieldelement(LineDiscount; SalesLine."Line Discount %")
                    {
                    }
                    textelement(NetPrice)
                    {
                        trigger OnBeforePassVariable()
                        var
                        begin
                            Clear(NetPrice);
                            if SalesLine."Line Discount %" > 0 then
                                NetPrice := format(SalesLine."Unit Price" - (SalesLine."Unit Price" * SalesLine."Line Discount %" / 100))
                            else
                                NetPrice := format(SalesLine."Unit Price");
                        end;
                    }
                    fieldelement(Amount; SalesLine.Amount)
                    {
                    }
                    fieldelement(AmountIncludingVAT; SalesLine."Amount Including VAT")
                    {
                    }
                    fieldelement(VATIdentifier; SalesLine."VAT Identifier")
                    {
                    }
                    fieldelement(VAT; SalesLine."VAT %")
                    {
                    }
                    fieldelement(SheetNumber; SalesLine."Sheet Number")
                    {
                    }
                    fieldelement(ToteNumber; SalesLine."Load Unit")
                    {
                    }
                    textelement(UnitPackSize)
                    {
                        trigger OnBeforePassVariable()
                        var
                            G_Item: Record Item;
                        begin
                            Clear(UnitPackSize);
                            G_Item.Reset();
                            G_Item.SetRange("No.", SalesLine."Item No.");
                            if G_Item.FindFirst() then begin
                                UnitPackSize := G_Item."Pack Size";
                            end;
                        end;
                    }

                    trigger OnPreXmlItem()
                    var
                    begin
                        SalesLine.SetCurrentKey("Load Unit");
                        SalesLine.Ascending(true);
                    end;
                }
            }
        }
    }

    var
        G_KnappOrderResponse: Record "Knapp Order Response";
}