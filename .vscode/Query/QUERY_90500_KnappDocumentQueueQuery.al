query 90500 Knapp_Document_Queue_Query
{
    QueryType = Normal;

    elements
    {
        dataitem(Knapp_Document_Queue; "Knapp Document Queue")
        {
            column(Entry_No_; "Entry No.")
            {
                Method = Max;
            }
        }
    }
}