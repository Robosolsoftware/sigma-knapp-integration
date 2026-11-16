table 90500 "Knapp Document Queue"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            TableRelation = User."User Name";
            DataClassification = ToBeClassified;
        }
        field(3; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionMembers = " ","Article Master","Customer Master","Route Master",Order,"Order Update","Order Delete","Customer Update","Route Update","Article Update","Article Delete";
            OptionCaption = ' ,Article Master,Customer Master,Route Master,Order,Order Update,Order Delete,Customer Update,Route Update,Article Update,Article Delete';
            DataClassification = ToBeClassified;
        }
        field(4; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'New,Completed,Error';
            OptionMembers = New,Completed,Error;
            DataClassification = ToBeClassified;
        }
        field(5; "Created Date/Time"; DateTime)
        {
            Caption = 'Created Date/Time';
            Editable = true;
            DataClassification = ToBeClassified;
        }
        field(6; "Request"; Text[2048])
        {
            Caption = 'Request';
            DataClassification = ToBeClassified;
        }
        field(7; "Response"; Text[2048])
        {
            Caption = 'Response';
            DataClassification = ToBeClassified;
        }
        field(8; "Updated Date/Time"; DateTime)
        {
            Caption = 'Updated Date/Time';
            Editable = true;
            DataClassification = ToBeClassified;
        }
        field(9; Remarks; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Document Reference No."; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Moved to Archive"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(12; "Converted to Non-Knapp"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(13; Update; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(14; "Marked as Error"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Entry No.", "Document Type")
        {
        }
    }

    var
        KnappToolbox: Codeunit "Knapp Toolbox";

    internal procedure GetRequestXMLAsText() ReturnXMLAsText: Text
    var
        IStream: InStream;
    begin
        // Rec.CalcFields(Request);
        // Rec.Request.CreateInStream(IStream, TextEncoding::UTF8);
        // KnappToolbox.TryReadXmlAsTextWithSeparator(IStream, KnappToolbox.LFSeparator(), ReturnXMLAsText);
        exit(Rec.Request);
    end;

    internal procedure GetResponseXMLAsText() ReturnXMLAsText: Text
    var
        IStream: InStream;
    begin
        // Rec.CalcFields(Response);
        // Rec.Response.CreateInStream(IStream, TextEncoding::UTF8);
        // KnappToolbox.TryReadXmlAsTextWithSeparator(IStream, KnappToolbox.LFSeparator(), ReturnXMLAsText);
        exit(Rec.Response);
    end;

    trigger OnDelete()
    var
        L_SalesLine: Record "Sales Line";
        L_SalesHeader: Record "Sales Header";
        L_Customer: Record Customer;
        L_ShippingAgentService: Record "Shipping Agent Services";
        ArticleReferenceList: List of [Text];
        ArticleItemNo: Text;
        ArticleReferenceNo: Text;
        L_ItemReference: Record "Item Reference";
    begin
        Case Rec."Document Type" of
            Rec."Document Type"::"Article Master":
                begin
                    if Rec.Status <> Rec.Status::Completed then begin
                        Clear(ArticleReferenceList);
                        Clear(ArticleReferenceNo);
                        Clear(ArticleItemNo);
                        ArticleReferenceList := Rec."Document Reference No.".Split('—');
                        ArticleItemNo := ArticleReferenceList.Get(1);
                        ArticleReferenceNo := ArticleReferenceList.Get(2);

                        L_ItemReference.Reset();
                        L_ItemReference.SetRange("Item No.", ArticleItemNo);
                        L_ItemReference.SetRange("Reference No.", ArticleReferenceNo);
                        L_ItemReference.SetRange("Reference Type", L_ItemReference."Reference Type"::"Article Number");
                        L_ItemReference.SetRange("Sent to Knapp", true);
                        if L_ItemReference.FindSet() then begin
                            repeat
                                L_ItemReference."Sent to Knapp" := false;
                                L_ItemReference.Modify();
                            until L_ItemReference.Next() = 0;
                        end;
                    end
                    else
                        Error('You can not delete the Completed Article Master record');
                end;

            Rec."Document Type"::"Customer Master":
                begin
                    if Rec.Status <> Rec.Status::Completed then begin
                        L_Customer.Reset();
                        L_Customer.SetRange("No.", Rec."Document Reference No.");
                        L_Customer.SetRange("Sent to Knapp", true);
                        if L_Customer.FindFirst() then begin
                            L_Customer."Sent to Knapp" := false;
                            L_Customer.Modify();
                        end;
                    end
                    else
                        Error('You can not delete the Completed Customer Master record');
                end;

            Rec."Document Type"::"Route Master":
                begin
                    if Rec.Status <> Rec.Status::Completed then begin
                        L_ShippingAgentService.Reset();
                        L_ShippingAgentService.SetRange(Code, Rec."Document Reference No.");
                        L_ShippingAgentService.SetRange("Sent to Knapp", true);
                        if L_ShippingAgentService.FindFirst() then begin
                            L_ShippingAgentService."Sent to Knapp" := false;
                            L_ShippingAgentService.Modify();
                        end;
                    end
                    else
                        Error('You can not delete the Completed Route Master record');
                end;

            Rec."Document Type"::Order:
                begin
                    L_SalesHeader.Reset();
                    L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
                    L_SalesHeader.SetRange("No.", Rec."Document Reference No.");
                    if L_SalesHeader.FindFirst() then begin
                        if Rec.Status <> Rec.Status::Completed then begin
                            if Rec."Converted to Non-Knapp" = false then begin
                                L_SalesHeader.CalcFields("Knapp Response Available");
                                if (L_SalesHeader."Knapp Response Available" = false) and (L_SalesHeader."Order Complete" = false) then begin
                                    L_SalesLine.Reset();
                                    L_SalesLine.SetFilter("Document Type", '%1', L_SalesLine."Document Type"::Order);
                                    L_SalesLine.SetFilter(Type, '%1', L_SalesLine.Type::Item);
                                    L_SalesLine.SetFilter("Document No.", Rec."Document Reference No.");
                                    L_SalesLine.SetRange("Knapp Line", true);
                                    L_SalesLine.SetRange("Sent to Knapp", true);
                                    if L_SalesLine.FindSet() then begin
                                        repeat
                                            L_SalesLine."Sent to Knapp" := false;
                                            L_SalesLine."Sheet Number" := 0;
                                            L_SalesLine."Load Unit" := '';
                                            L_SalesLine.Remarks := '';
                                            L_SalesLine.Modify(true);
                                        until L_SalesLine.Next() = 0;
                                    end;
                                end;

                                Commit();
                            end
                            else
                                Error('You can not delete the converted to Non-Knapp records');
                        end
                        else
                            Error('To delete Completed Orders use action "Delete Completed Order"');
                    end;
                end;
        End;
    end;
}