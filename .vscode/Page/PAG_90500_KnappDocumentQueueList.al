page 90500 "Knapp Document Queue List"
{
    Caption = 'Knapp Document Queue List';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Document,Analyze performance';
    SaveValues = true;
    SourceTable = "Knapp Document Queue";
    SourceTableView = SORTING("Entry No.")
                      ORDER(Descending);
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = true;

    layout
    {
        area(Content)
        {
            grid(Grid01)
            {
                group("Filter")
                {
                    Caption = 'Filter';
                    field(ShowAllCheckBox; ShowAll)
                    {
                        Caption = 'Show All';
                        ToolTip = 'Remove all current filters and display all Queue entries.';
                        Editable = ShowAllCheckBoxEditable;
                        ApplicationArea = All;

                        trigger OnValidate();
                        begin
                            ShowAllOnAfterValidate();
                        end;
                    }
                }

                group(StatusFilter)
                {
                    Caption = '', Locked = true;
                    field(ShowNewCheckBox; ShowNew)
                    {
                        Caption = 'New';
                        ToolTip = 'Filter queue entries to (unprocessed) entries with status New.';
                        ApplicationArea = All;

                        trigger OnValidate();
                        begin
                            ShowNewOnAfterValidate();
                        end;
                    }
                    field(ShowCompletedCheckBox; ShowCompleted)
                    {
                        Caption = 'Completed';
                        ToolTip = 'Display completed queue entries only.';
                        ApplicationArea = All;

                        trigger OnValidate();
                        begin
                            ShowCompletedOnAfterValidate();
                        end;
                    }
                    field(ShowerrorCheckBox; Showerror)
                    {
                        Caption = 'Error';
                        ToolTip = 'Display queue entries that failed during processing.';
                        ApplicationArea = All;

                        trigger OnValidate();
                        begin
                            ShowerrorOnAfterValidate();
                        end;
                    }
                }
            }

            repeater(Control1)
            {
                Editable = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ToolTip = 'The request Document Type being processed.';
                    ApplicationArea = All;
                }
                field("Document Reference No."; Rec."Document Reference No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Processing status for this current Knapp Document Queue entry.';
                    ApplicationArea = All;
                }
                field(Request; Rec.Request)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Response; Rec.Response)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Created Date/Time"; Rec."Created Date/Time")
                {
                    ToolTip = 'Date/Time this current request was inserted into the Knapp Document Queue.';
                    ApplicationArea = All;
                }
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'The User ID the request was created from.';
                    ApplicationArea = All;
                }
                field(Update; Rec.Update)
                {
                    ApplicationArea = All;
                }
                field("Converted to Non-Knapp"; Rec."Converted to Non-Knapp")
                {
                    ToolTip = 'If true means Order is Converted into a Non-Knapp Order';
                    ApplicationArea = All;
                }
                field("Marked as Error"; Rec."Marked as Error")
                {
                    ToolTip = 'If true means order status is manually changed to Error';
                    ApplicationArea = All;
                }
                field(Remarks; Rec.Remarks)
                {
                    ApplicationArea = All;
                }
            }

            group(RequestDoc)
            {
                Caption = 'Request';

                usercontrol(RequestControl; WebPageViewer) //"Microsoft.Dynamics.Nav.Client.WebPageViewer"
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        RequestAddInReady := true;
                        FillRequestHtmlViewerAddIn();
                    end;
                }
            }

            group(ResponseDoc)
            {
                Caption = 'Response';

                usercontrol(ResponseControl; WebPageViewer) //"Microsoft.Dynamics.Nav.Client.WebPageViewer"
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        ResponseAddInReady := true;
                        FillResponseHtmlViewerAddIn();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group("Function")
            {
                Caption = 'Functions';
                action("Delete & Generate Article Masters")
                {
                    ToolTip = 'Delete and Generate Initial Article Master documents ready for processing.';
                    ApplicationArea = All;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                    begin
                        Clear(CU_KnappGenerateDocument);
                        if Confirm('Do you really want to delete all the Article Master entries?') then begin
                            CU_KnappGenerateDocument.DeleteArticleMasters();
                        end;
                        CU_KnappGenerateDocument.GenerateInitialArticleMaster();
                        Message('Process Complete');
                    end;
                }

                action("Generate Article Master")
                {
                    Caption = 'Generate Article Master';
                    ToolTip = 'Generate Article Master documents ready for processing.';
                    ApplicationArea = All;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Visible = false;

                    trigger OnAction();
                    var
                    begin
                        Clear(CU_KnappGenerateDocument);
                        CU_KnappGenerateDocument.GenerateArticleMaster();
                        Message('Process Completed');
                    end;
                }

                action("Generate Customer Master")
                {
                    Caption = 'Generate Customer Master';
                    ToolTip = 'Generate Customer Master documents ready for processing.';
                    ApplicationArea = All;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction();
                    var
                    begin
                        Clear(CU_KnappGenerateDocument);
                        CU_KnappGenerateDocument.GenerateCustomerMaster();
                        Message('Process Completed');
                    end;
                }

                action("Generate Route Master")
                {
                    Caption = 'Generate Route Master';
                    ToolTip = 'Generate Route Master documents ready for processing.';
                    ApplicationArea = All;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction();
                    var
                    begin
                        Clear(CU_KnappGenerateDocument);
                        CU_KnappGenerateDocument.GenerateRouteMaster();
                        Message('Process Completed');
                    end;
                }

                action("Generate Orders")
                {
                    Caption = 'Generate Orders';
                    ToolTip = 'Generate Order documents ready for processing.';
                    ApplicationArea = All;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction();
                    var
                    begin
                        Clear(CU_KnappGenerateDocument);
                        CU_KnappGenerateDocument.GenerateOrdersNew();
                        //CU_KnappGenerateDocument.GenerateOrders();
                    end;
                }

                action("Mark Order as Error")
                {
                    Caption = 'Mark Order as Error';
                    ToolTip = 'Change the status of the order from Completed to Error.';
                    ApplicationArea = All;
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        L_KnappDocumentQueue: Record "Knapp Document Queue";
                        CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                        OrderResponseExist: Boolean;
                    begin
                        if Confirm('Do you really want to change Selected Orders status into Error?') then begin
                            Clear(L_KnappDocumentQueue);
                            L_KnappDocumentQueue := Rec;
                            CurrPage.SetSelectionFilter(L_KnappDocumentQueue);

                            L_KnappDocumentQueue.SetRange("Document Type", L_KnappDocumentQueue."Document Type"::Order);
                            L_KnappDocumentQueue.SetRange(Status, L_KnappDocumentQueue.Status::Completed);
                            if L_KnappDocumentQueue.FindSet() then begin
                                repeat
                                    OrderResponseExist := false;
                                    OrderResponseExist := CU_KnappGenerateDocument.CheckOrderResponseExist(L_KnappDocumentQueue);

                                    if OrderResponseExist = false then begin
                                        L_KnappDocumentQueue.Status := L_KnappDocumentQueue.Status::Error;
                                        L_KnappDocumentQueue."Marked as Error" := true;
                                        L_KnappDocumentQueue.Modify();

                                        if Confirm(StrSubstNo('Do you really want to delete Order %1 from knapp?', L_KnappDocumentQueue."Document Reference No.")) then begin
                                            CU_KnappGenerateDocument.GenerateDeleteOrderRequest(L_KnappDocumentQueue);
                                        end;
                                        Commit();
                                    end;
                                until L_KnappDocumentQueue.Next() = 0;
                            end;

                            Message('Process Completed');
                        end;
                    end;
                }

                action("Knapp to Non-Knapp")
                {
                    Caption = 'Knapp to Non-Knapp';
                    ToolTip = 'Convert the Error Orders into non-Knapp (Manual) Orders';
                    ApplicationArea = All;
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                        L_KnappDocumentQueue: Record "Knapp Document Queue";
                    begin
                        if Confirm('Do you really want to convert Selected Orders into Non-Knapp Orders?') then begin
                            Clear(L_KnappDocumentQueue);
                            L_KnappDocumentQueue := Rec;
                            CurrPage.SetSelectionFilter(L_KnappDocumentQueue);

                            L_KnappDocumentQueue.SetRange("Document Type", L_KnappDocumentQueue."Document Type"::Order);
                            L_KnappDocumentQueue.SetRange(Status, L_KnappDocumentQueue.Status::Error);
                            L_KnappDocumentQueue.SetRange("Converted to Non-Knapp", false);
                            if L_KnappDocumentQueue.FindSet() then begin
                                repeat
                                    CU_KnappGenerateDocument.ConvertKnappToNonKnapp(L_KnappDocumentQueue);
                                until L_KnappDocumentQueue.Next() = 0;
                            end;

                            Message('Process Completed');
                        end;
                    end;
                }

                action("Delete Completed Order")
                {
                    Caption = 'Delete Completed Order';
                    ToolTip = 'This will Delete the selected filter Order documents and generate new requests for Delete Order.';
                    ApplicationArea = All;
                    Image = Delete;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        L_KnappDocumentQueue: Record "Knapp Document Queue";
                        CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                    begin
                        if Confirm('Do you really want to delete Selected Orders from knapp?') then begin
                            Clear(L_KnappDocumentQueue);
                            L_KnappDocumentQueue := Rec;
                            CurrPage.SetSelectionFilter(L_KnappDocumentQueue);

                            L_KnappDocumentQueue.SetRange("Document Type", L_KnappDocumentQueue."Document Type"::Order);
                            L_KnappDocumentQueue.SetRange(Status, L_KnappDocumentQueue.Status::Completed);
                            if L_KnappDocumentQueue.FindSet() then begin
                                repeat
                                    CU_KnappGenerateDocument.GenerateKnappDeleteOrderRequest(L_KnappDocumentQueue);
                                until L_KnappDocumentQueue.Next() = 0;
                            end;

                            Message('Process Completed');
                        end;
                    end;
                }

                action("Sync Order Responses")
                {
                    Caption = 'Sync Order Responses';
                    ToolTip = 'This will sync Order Response documents ready for processing.';
                    ApplicationArea = All;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Visible = true;

                    trigger OnAction();
                    var
                        L_KnappDocumentQueue: Record "Knapp Document Queue";
                        UserSetup: Record "User Setup";
                    begin
                        UserSetup.Reset();
                        if UserSetup.Get(UserId) then begin
                            if UserSetup."Knapp Permission" = true then begin
                                L_KnappDocumentQueue.Reset();
                                L_KnappDocumentQueue.SetFilter("Document Type", '%1', L_KnappDocumentQueue."Document Type"::"Order Update");
                                L_KnappDocumentQueue.SetFilter("Document Reference No.", '<>%1', '');
                                L_KnappDocumentQueue.SetFilter(Status, '%1', L_KnappDocumentQueue.Status::New);
                                L_KnappDocumentQueue.SetFilter(Request, '<>%1', '');
                                if L_KnappDocumentQueue.FindSet() then begin
                                    repeat
                                        Clear(CU_KnappGenerateDocument);
                                        CU_KnappGenerateDocument.SyncOrderResponses(L_KnappDocumentQueue);
                                    until L_KnappDocumentQueue.Next() = 0;
                                end;
                                Message('Process Completed');
                            end
                            else begin
                                Message('You do not have permission to sync the knapp responses.');
                            end;
                        end;
                    end;
                }

                action("Delete & Generate Initial Route Master")
                {
                    ToolTip = 'Delete and Generate Initial Route Master documents ready for processing.';
                    ApplicationArea = All;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                    begin
                        if Confirm('Do you really want to delete all the Route Master entries?') then begin
                            CU_KnappGenerateDocument.DeleteRouteMasters();
                        end;
                        CU_KnappGenerateDocument.GenerateInitialRouteMaster();
                        Message('Process Complete');
                    end;
                }

                action("Delete & Generate Initial Customer Master")
                {
                    ToolTip = 'Delete and Generate Initial Customer Master documents ready for processing.';
                    ApplicationArea = All;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";
                    begin
                        if Confirm('Do you really want to delete all the Customer Master entries?') then begin
                            CU_KnappGenerateDocument.DeleteCustomerMasters();
                        end;
                        CU_KnappGenerateDocument.GenerateInitialCustomerMaster();
                        Message('Process Complete');
                    end;
                }

                action("Bulk Delete Masters")
                {
                    ApplicationArea = All;
                    Image = Delete;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'This button is for Bulk deletion of records irrespective of any Validations';

                    trigger OnAction()
                    var
                        L_KnappDocumentQueue: Record "Knapp Document Queue";
                        UserSetup: Record "User Setup";
                    begin
                        UserSetup.Reset();
                        if UserSetup.Get(UserId) then begin
                            if UserSetup."Knapp Permission" = true then begin
                                if Confirm('Do you really want to delete Selected records?') then begin
                                    Clear(L_KnappDocumentQueue);
                                    L_KnappDocumentQueue := Rec;
                                    CurrPage.SetSelectionFilter(L_KnappDocumentQueue);

                                    if L_KnappDocumentQueue.FindSet() then begin
                                        repeat
                                            DeleteMasterData(L_KnappDocumentQueue);
                                            Commit();
                                        until L_KnappDocumentQueue.Next() = 0;
                                    end;
                                    Message('Process Completed');
                                end;
                            end
                            else begin
                                Message('You do not have permission to delete knapp document queue.');
                            end;
                        end;
                    end;
                }

                action("Set as New")
                {
                    Caption = 'Set as New';
                    ToolTip = 'Set the selected errored/Completed documents to New Status.';
                    ApplicationArea = All;
                    Image = NewStatusChange;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    // Visible = false;

                    trigger OnAction();
                    var
                        KnappDocumentQueue: Record "Knapp Document Queue";
                    begin
                        Clear(KnappDocumentQueue);
                        KnappDocumentQueue := Rec;
                        CurrPage.SetSelectionFilter(KnappDocumentQueue);
                        KnappDocumentQueue.SetFilter(Status, '%1|%2', KnappDocumentQueue.Status::Error, KnappDocumentQueue.Status::Completed);
                        if KnappDocumentQueue.FindSet() then begin
                            repeat
                                KnappDocumentQueue.Status := KnappDocumentQueue.Status::New;
                                KnappDocumentQueue.Modify();
                            until KnappDocumentQueue.Next() = 0;
                        end;
                    end;
                }
                action("Delete Record")
                {
                    // want to delete the knapp documnet queue for document type Order
                    ApplicationArea = All;
                    Image = Delete;
                    ToolTip = 'This button is for deletion of Order documents from Knapp Document Queue.';
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        L_KnappDocumentQueue: Record "Knapp Document Queue";
                        UserSetup: Record "User Setup";
                    begin
                        UserSetup.Reset();
                        if UserSetup.Get(UserId) then begin
                            if UserSetup."Knapp Permission" = true then begin
                                if Confirm('Do you really want to delete Selected records?') then begin
                                    Clear(L_KnappDocumentQueue);
                                    L_KnappDocumentQueue := Rec;
                                    CurrPage.SetSelectionFilter(L_KnappDocumentQueue);
                                    //L_KnappDocumentQueue.SetFilter("Document Type", '%1|%2', L_KnappDocumentQueue."Document Type"::Order, L_KnappDocumentQueue."Document Type"::"Order Update");
                                    if L_KnappDocumentQueue.FindSet() then begin
                                        L_KnappDocumentQueue.DeleteAll(false);
                                    end;
                                    Message('Process Completed');
                                end;
                            end else begin
                                Message('You do not have permission to delete knapp document queue.');
                            end;
                        end;
                    end;
                }
            }
        }
    }

    var
        ShowAll: Boolean;
        ShowAllCheckBoxEditable: Boolean;
        ShowNew: Boolean;
        ShowCompleted: Boolean;
        Showerror: Boolean;
        FilterStatus: Text[2048];
        RequestAddInReady: Boolean;
        ResponseAddInReady: Boolean;
        CU_KnappGenerateDocument: Codeunit "Knapp Generate Documents";

    trigger OnInit();
    begin
        ShowAllCheckBoxEditable := true;
    end;

    trigger OnOpenPage();
    begin
        if not ShowNew and
           not ShowCompleted and
           not Showerror
        then
            SetShowAll()
        else
            ValidateFilter();
        if not Rec.FindFirst() then;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if RequestAddInReady then
            FillRequestHtmlViewerAddIn();

        if ResponseAddInReady then
            FillResponseHtmlViewerAddIn();
    end;

    local procedure ShowAllOnAfterValidate()
    begin
        SetShowAll();
    end;

    local procedure SetShowAll()
    begin
        ShowNew := true;
        ShowCompleted := true;
        Showerror := true;

        ValidateFilter();
    end;

    local procedure ShowNewOnAfterValidate()
    begin
        ValidateFilter();
    end;

    local procedure ShowerrorOnAfterValidate()
    begin
        ValidateFilter();
    end;

    local procedure ShowCompletedOnAfterValidate()
    begin
        ValidateFilter();
    end;

    local procedure ValidateFilter()
    begin
        BuildStatusFilter();
        ShowAll := (FilterStatus = '');
        Rec.SetFilter(Status, FilterStatus);
        ShowAllCheckBoxEditable := not ShowAll;
        Rec.FilterGroup(0);

        CurrPage.Update(false);
    end;

    local procedure BuildStatusFilter()
    begin
        FilterStatus := '';
        if ShowNew and ShowCompleted and Showerror then
            exit;

        if ShowNew then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::New);

        if ShowCompleted then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::Completed);

        if Showerror then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::Error);

        if FilterStatus <> '' then
            FilterStatus := CopyStr(FilterStatus, 2)
        else
            FilterStatus :=
              StrSubstNo(
                '<>%1&<>%2&<>%3', Format(Rec.Status::New), Format(Rec.Status::Completed), Format(Rec.Status::Error));
    end;

    local procedure FillRequestHtmlViewerAddIn()
    var
        HtmlMgt: Codeunit "Knapp HTML Management";
    begin
        CurrPage.RequestControl.SetContent(HtmlMgt.CreateHtmlWithTextArea(Rec.GetRequestXMLAsText()));
    end;

    local procedure FillResponseHtmlViewerAddIn()
    var
        HtmlMgt: Codeunit "Knapp HTML Management";
    begin
        CurrPage.ResponseControl.SetContent(HtmlMgt.CreateHtmlWithTextArea(Rec.GetResponseXMLAsText()));
    end;

    trigger OnDeleteRecord(): Boolean
    var
    begin
        CurrPage.Update();
    end;

    local procedure DeleteMasterData(var P_KnappDocumentQueue: Record "Knapp Document Queue")
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
        Case P_KnappDocumentQueue."Document Type" of
            P_KnappDocumentQueue."Document Type"::"Article Master":
                begin
                    Clear(ArticleReferenceList);
                    Clear(ArticleReferenceNo);
                    Clear(ArticleItemNo);
                    ArticleReferenceList := P_KnappDocumentQueue."Document Reference No.".Split('—');
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
                end;

            P_KnappDocumentQueue."Document Type"::"Customer Master":
                begin
                    L_Customer.Reset();
                    L_Customer.SetRange("No.", P_KnappDocumentQueue."Document Reference No.");
                    L_Customer.SetRange("Sent to Knapp", true);
                    if L_Customer.FindFirst() then begin
                        L_Customer."Sent to Knapp" := false;
                        L_Customer.Modify();
                    end;
                end;

            P_KnappDocumentQueue."Document Type"::"Route Master":
                begin
                    L_ShippingAgentService.Reset();
                    L_ShippingAgentService.SetRange(Code, P_KnappDocumentQueue."Document Reference No.");
                    L_ShippingAgentService.SetRange("Sent to Knapp", true);
                    if L_ShippingAgentService.FindFirst() then begin
                        L_ShippingAgentService."Sent to Knapp" := false;
                        L_ShippingAgentService.Modify();
                    end;
                end;

            P_KnappDocumentQueue."Document Type"::Order:
                begin
                    L_SalesHeader.Reset();
                    L_SalesHeader.SetRange("Document Type", L_SalesHeader."Document Type"::Order);
                    L_SalesHeader.SetRange("No.", P_KnappDocumentQueue."Document Reference No.");
                    if L_SalesHeader.FindFirst() then begin
                        if P_KnappDocumentQueue."Converted to Non-Knapp" = false then begin
                            L_SalesHeader.CalcFields("Knapp Response Available");
                            if (L_SalesHeader."Knapp Response Available" = false) and (L_SalesHeader."Order Complete" = false) then begin
                                L_SalesLine.Reset();
                                L_SalesLine.SetFilter("Document Type", '%1', L_SalesLine."Document Type"::Order);
                                L_SalesLine.SetFilter(Type, '%1', L_SalesLine.Type::Item);
                                L_SalesLine.SetFilter("Document No.", P_KnappDocumentQueue."Document Reference No.");
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
                    end;
                end;
        End;

        P_KnappDocumentQueue.Delete();
    end;
}