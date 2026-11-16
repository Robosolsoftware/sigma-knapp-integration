page 90505 "Archive Knapp Document Queues"
{
    Caption = 'Archive Knapp Document Queue List';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Document,Analyze performance';
    SaveValues = true;
    SourceTable = "Archive Knapp Document Queue";
    SourceTableView = SORTING("Entry No.")
                      ORDER(Descending);
    UsageCategory = Administration;
    ApplicationArea = All;

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
                    field(ShowProcessingCheckBox; ShowProcessing)
                    {
                        Caption = 'Processing';
                        ToolTip = 'Filter queue entries to entries currently being processed (Status = Processing).';
                        ApplicationArea = All;

                        trigger OnValidate();
                        begin
                            ShowProcessingOnAfterValidate();
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

                usercontrol(RequestControl; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
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

                usercontrol(ResponseControl; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
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

    var
        ShowAll: Boolean;
        ShowAllCheckBoxEditable: Boolean;
        ShowNew: Boolean;
        ShowProcessing: Boolean;
        ShowCompleted: Boolean;
        Showerror: Boolean;
        FilterStatus: Text[2048];
        RequestAddInReady: Boolean;
        ResponseAddInReady: Boolean;

    trigger OnInit();
    begin
        ShowAllCheckBoxEditable := true;
    end;

    trigger OnOpenPage();
    begin
        if not ShowNew and
           not ShowProcessing and
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
        ShowProcessing := true;
        ShowCompleted := true;
        Showerror := true;

        ValidateFilter();
    end;

    local procedure ShowNewOnAfterValidate()
    begin
        ValidateFilter();
    end;

    local procedure ShowProcessingOnAfterValidate()
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
        if ShowNew and ShowProcessing and ShowCompleted and Showerror then
            exit;

        if ShowNew then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::New);

        if ShowProcessing then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::Processing);

        if ShowCompleted then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::Completed);

        if Showerror then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::Error);

        if FilterStatus <> '' then
            FilterStatus := CopyStr(FilterStatus, 2)
        else
            FilterStatus :=
              StrSubstNo(
                '<>%1&<>%2&<>%3&<>%4', Format(Rec.Status::New), Format(Rec.Status::Processing), Format(Rec.Status::Completed), Format(Rec.Status::Error));
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
}