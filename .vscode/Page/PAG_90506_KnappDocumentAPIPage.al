page 90506 "Knapp Document API Page"
{
    PageType = API;
    SourceTable = "Knapp Document Queue";
    APIPublisher = 'Robosol';
    APIGroup = 'knappdocuments';
    APIVersion = 'v1.0';
    EntitySetName = 'knapp';
    EntityName = 'knapp';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Entry_No; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Document_Type; Rec."Document Type")
                {
                    ToolTip = 'The request Document Type being processed.';
                    ApplicationArea = All;
                }
                field(Document_Reference_No; Rec."Document Reference No.")
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
                field(Created_Date_Time; Rec."Created Date/Time")
                {
                    ToolTip = 'Date/Time this current request was inserted into the Knapp Document Queue.';
                    ApplicationArea = All;
                }
                field(User_ID; Rec."User ID")
                {
                    ToolTip = 'The User ID the request was created from.';
                    ApplicationArea = All;
                }
                field(Update; Rec.Update)
                {
                    ApplicationArea = All;
                }
                field(Converted_to_Non_Knapp; Rec."Converted to Non-Knapp")
                {
                    ApplicationArea = All;
                }
                field(Remarks; Rec.Remarks)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}