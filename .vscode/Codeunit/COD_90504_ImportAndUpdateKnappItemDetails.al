codeunit 90504 "Import Excel to Update Knapp"
{
    trigger OnRun()
    begin
        ImportJobJournalExcel();
    end;

    local procedure ImportJobJournalExcel()
    var
        ItemNo: Code[20];
        ReferenceNo: Code[50];
        PackSize: Integer;
        VariantCode: Code[10];
        L_KnappItemDetails: Record "Knapp Item Details";
    begin
        G_ExcelBuffer.DeleteAll();
        Rows := 0;
        Columns := 0;
        DialogCaption := 'Select File to upload';
        UploadResult := UploadIntoStream(DialogCaption, '', '', Name, FileInStream);

        If Name <> '' then
            Sheetname := G_ExcelBuffer.SelectSheetsNameStream(FileInStream)
        else
            exit;

        G_ExcelBuffer.Reset();
        G_ExcelBuffer.OpenBookStream(FileInStream, Sheetname);
        G_ExcelBuffer.ReadSheet();
        Commit();

        //finding total number of Rows to Import
        G_ExcelBuffer.Reset();
        G_ExcelBuffer.SetRange("Column No.", 1);
        If G_ExcelBuffer.FindFirst() then begin
            repeat
                Rows := Rows + 1;
            until G_ExcelBuffer.Next() = 0;
        end;

        //Finding total number of columns to import
        G_ExcelBuffer.Reset();
        G_ExcelBuffer.SetRange("Row No.", 1);
        if G_ExcelBuffer.FindFirst() then begin
            repeat
                Columns := Columns + 1;
            until G_ExcelBuffer.Next() = 0;
        end;

        for RowNo := 2 to Rows do begin
            Clear(ItemNo);
            Clear(ReferenceNo);
            Clear(PackSize);
            Clear(VariantCode);
            ItemNo := GetValueAtIndex(RowNo, 3);
            ReferenceNo := GetValueAtIndex(RowNo, 4);
            Evaluate(PackSize, GetValueAtIndex(RowNo, 10));
            VariantCode := GetValueAtIndex(RowNo, 11);

            L_KnappItemDetails.Reset();
            L_KnappItemDetails.SetRange("Item No.", ItemNo);
            L_KnappItemDetails.SetRange("Item Reference No.", ReferenceNo);
            L_KnappItemDetails.SetRange("Item Reference Type", L_KnappItemDetails."Item Reference Type"::"Article Number");
            L_KnappItemDetails.SetRange("Item Variant Code", VariantCode);
            L_KnappItemDetails.SetFilter("Knapp Pack Size", '%1', PackSize);
            if not L_KnappItemDetails.FindFirst() then begin
                L_KnappItemDetails.Reset();
                L_KnappItemDetails.SetRange("Item No.", ItemNo);
                L_KnappItemDetails.SetRange("Item Reference No.", ReferenceNo);
                L_KnappItemDetails.SetRange("Item Reference Type", L_KnappItemDetails."Item Reference Type"::"Article Number");
                L_KnappItemDetails.SetRange("Item Variant Code", VariantCode);
                if L_KnappItemDetails.FindFirst() then begin
                    Clear(G_KnappItemDetails);
                    G_KnappItemDetails.Reset();
                    G_KnappItemDetails.Init();
                    G_KnappItemDetails."Entry No." := GetLastEntryNo() + 1;
                    G_KnappItemDetails."Item No." := ItemNo;
                    G_KnappItemDetails."Item Reference No." := ReferenceNo;
                    G_KnappItemDetails."Item Reference Type" := G_KnappItemDetails."Item Reference Type"::"Article Number";
                    G_KnappItemDetails."Item Variant Code" := VariantCode;
                    G_KnappItemDetails.Validate("Knapp Aisle", L_KnappItemDetails."Knapp Aisle");
                    G_KnappItemDetails."Knapp Ejection No" := L_KnappItemDetails."Knapp Ejection No";
                    G_KnappItemDetails.Validate("Knapp Maximum Stock", L_KnappItemDetails."Knapp Maximum Stock");
                    G_KnappItemDetails.Validate("Knapp Minimum Stock", L_KnappItemDetails."Knapp Minimum Stock");
                    G_KnappItemDetails.Validate("Knapp Pack Size", PackSize);
                    G_KnappItemDetails.Validate("Knapp Position", L_KnappItemDetails."Knapp Position");
                    G_KnappItemDetails.Validate("Knapp Rack", L_KnappItemDetails."Knapp Rack");
                    G_KnappItemDetails.Validate("Knapp Rack Level", L_KnappItemDetails."Knapp Rack Level");
                    G_KnappItemDetails."Knapp Station Number" := L_KnappItemDetails."Knapp Station Number";
                    G_KnappItemDetails."Knapp Storage Location" := L_KnappItemDetails."Knapp Storage Location";
                    G_KnappItemDetails."Overstock Storage Location" := L_KnappItemDetails."Overstock Storage Location";
                    G_KnappItemDetails.Insert(true);
                    Commit();
                end;
            end;
        end;
        Message('Import Completed');
    end;

    local procedure GetValueAtIndex(RowNo: Integer; ColNo: Integer): Text
    var
        G_ExcelBuffer: Record "Excel Buffer";
    begin
        G_ExcelBuffer.Reset();
        If G_ExcelBuffer.Get(RowNo, ColNo) then
            exit(G_ExcelBuffer."Cell Value as Text");
    end;

    local procedure GetLastEntryNo(): Integer
    var
        L_KnappItemDetails: Record "Knapp Item Details";
    begin
        Clear(L_KnappItemDetails);
        L_KnappItemDetails.Reset();
        if L_KnappItemDetails.FindLast() then
            exit(L_KnappItemDetails."Entry No.");
    end;

    var
        G_ExcelBuffer: Record "Excel Buffer";
        Rows: Integer;
        Columns: Integer;
        Sheetname: Text;
        UploadResult: Boolean;
        DialogCaption: Text;
        Name: Text;
        FileInStream: InStream;
        RowNo: Integer;
        G_KnappItemDetails: Record "Knapp Item Details";
}