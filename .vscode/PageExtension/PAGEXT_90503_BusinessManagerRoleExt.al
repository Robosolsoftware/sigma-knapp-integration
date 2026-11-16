pageextension 90503 "Business Manager Role Ext" extends "Business Manager Role Center"
{
    actions
    {
        addlast(sections)
        {
            group(Knapp)
            {
                action("Knapp Document Queue List")
                {
                    RunObject = page "Knapp Document Queue List";
                    ApplicationArea = All;
                }
                action("Knapp Routes")
                {
                    RunObject = page "Shipping Agent Services";
                    ApplicationArea = All;
                }
                action("Knapp Station Numbers")
                {
                    RunObject = page "Knapp Station Numbers";
                    ApplicationArea = All;
                }
                action("Knapp Article List")
                {
                    RunObject = page "Item Reference List";
                    RunPageView = where("Reference Type" = filter('Article Number'));
                    ApplicationArea = All;
                }
            }
        }
    }
}