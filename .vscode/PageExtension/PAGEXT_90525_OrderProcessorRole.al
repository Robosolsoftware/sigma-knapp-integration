pageextension 90525 "Ext Order Processor" extends "Order Processor Role Center"
{
    layout
    {
        addbefore("User Tasks Activities")
        {
            part(CustomCue; "Custom Cue")
            {
                ApplicationArea = All;
            }
        }

    }
}