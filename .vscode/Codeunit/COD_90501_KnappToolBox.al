codeunit 90501 "Knapp Toolbox"
{
    trigger OnRun();
    begin
    end;

    var
        UnsupportedVariantTypeErr: Label 'Internal error: Unsupported in Variant type for parameter _NewValue in MOBToolbox.VariantToTextResponseFormat(). Variant value is %1', Comment = '%1 contains formatted value of input. May not be able to always format', Locked = true;
        BinGS1AiTxt: Label '00', Locked = true;
        ItemNoGS1AiTxt: Label '02,01,91', Locked = true;
        LotNoGS1AiTxt: Label '10', Locked = true;
        SerialNoGS1AiTxt: Label '21', Locked = true;
        PackageNoGS1AiTxt: Label '92', Locked = true;
        ExpirationDateGS1AiTxt: Label '17,15,12', Locked = true;
        QuantityGS1AiTxt: Label '310,30,37', Locked = true;

    //
    // ----- RESPONSE HANDLER  --
    // 





    /// <summary>
    /// Convert a Variant (record) into RecordRef
    /// </summary>
    procedure Variant2RecRef(_RecRelatedVariant: Variant; var _RecRef: RecordRef): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        if DataTypeManagement.GetRecordRef(_RecRelatedVariant, _RecRef) then
            exit(_RecRef.Number <> 0);
    end;

    /// <summary>
    /// Convert a Variant (record) into RecordID as text
    /// </summary>
    internal procedure Variant2RecordID(_Variant: Variant): Text
    var
        RecRef: RecordRef;
    begin
        if Variant2RecRef(_Variant, RecRef) then
            exit(Format(RecRef.RecordId(), 0, 9)); // 9 = Use the non-captioned data value, so the text always can be used with Evaluate() 
    end;

    internal procedure FindFieldValueByName(_Record: Variant; _FieldName: Text; var _ReturnValueAsVariant: Variant) ReturnSuccess: Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        FRef: FieldRef;
        RecRef: RecordRef;
    begin
        if Variant2RecRef(_Record, RecRef) then
            if DataTypeManagement.FindFieldByName(RecRef, FRef, _FieldName) then begin
                _ReturnValueAsVariant := FRef.Value;
                ReturnSuccess := true;
            end;
    end;

    internal procedure FindFieldValueAsText(_Record: Variant; _FieldName: Text) _ReturnValue: Text
    var
        TempVariant: Variant;
    begin
        if FindFieldValueByName(_Record, _FieldName, TempVariant) then
            _ReturnValue := TempVariant;
    end;

    internal procedure FindFieldValueAsInteger(_Record: Variant; _FieldName: Text) ReturnValue: Integer
    var
        TempVariant: Variant;
    begin
        if FindFieldValueByName(_Record, _FieldName, TempVariant) then
            ReturnValue := AsInteger(TempVariant);
    end;

    /// <summary>
    /// Convert a numerical (Option or Enum) to Integer. Replaces standard Enum.AsInteger() method for backwards compatibility.
    /// </summary>
    procedure AsInteger(_EnumOrOption: Variant) _Integer: Integer
    begin
        Evaluate(_Integer, format(_EnumOrOption, 0, 9));
    end;

    /// <summary>
    /// Convert a text versions of RecordId into a RecordRef
    /// </summary>
    procedure ReferenceIDText2RecRef(_ReferenceIDAsText: Text; var _ReturnRecRef: RecordRef): Boolean
    var
        ReferenceID: RecordId;
    begin
        if _ReferenceIDAsText = '' then
            exit;
        if Evaluate(ReferenceID, _ReferenceIDAsText) then
            exit(_ReturnRecRef.Get(ReferenceID));
    end;

    // Clone of TypeHelper.CRLFSeparator() (do not exist in BC13 and BC14)
    procedure CRLFSeparator(): Text[2]
    var
        CRLF: Text[2];
    begin
        CRLF[1] := 13; // Carriage return, '\r'
        CRLF[2] := 10; // Line feed, '\n'
        exit(CRLF);
    end;

    // Clone of TypeHelper.LFSeparator() (do not exist in BC13 and BC14)
    internal procedure LFSeparator(): Text[1]
    var
        LF: Text[1];
    begin
        LF[1] := 10; // Line feed, '\n'
        exit(LF);
    end;

    /// <summary>
    /// Try reading an XMLDoc from InStream as text
    /// </summary>
    internal procedure TryReadXmlAsTextWithSeparator(InStream: InStream; LineSeparator: Text; var Content: Text)
    begin
        if not TryReadAsTextWithSeparator(InStream, LineSeparator, Content) then
            Content := 'Error occurred while reading XML.';
    end;

    // Clone of TypeHelper.TryReadAsTextWithSeparator() (does not exist in pre BC17 versions)
    [TryFunction]
    internal procedure TryReadAsTextWithSeparator(InStream: InStream; LineSeparator: Text; var Content: Text)
    begin
        Content := ReadAsTextWithSeparator(InStream, LineSeparator);
    end;

    // Clone of TypeHelper.ReadAsTextWithSeparator() (does not exist in pre BC17 versions)
    internal procedure ReadAsTextWithSeparator(InStream: InStream; LineSeparator: Text) Content: Text
    var
        Tb: TextBuilder;
        ContentLine: Text;
    begin
        InStream.ReadText(ContentLine);
        Tb.Append(ContentLine);
        while not InStream.EOS do begin
            InStream.ReadText(ContentLine);
            Tb.Append(LineSeparator);
            Tb.Append(ContentLine);
        end;

        exit(Tb.ToText());
    end;

    // Based on dotnet String.Join
    internal procedure JoinText(_Text1: Text; _Text2: Text; _Separator: Text) ReturnText: Text
    begin
        ReturnText := _Text1 + _Separator + _Text2;
        ReturnText := ReturnText.TrimStart(_Separator);
        ReturnText := ReturnText.TrimEnd(_Separator);
        exit(ReturnText);
    end;

    procedure ReadBarcode(_FullBarcode: Text; var _BarCodeArray: Array[20, 2] of Text)
    var
        pos: Integer;
        "count": Integer;
        IdLen: Integer;
        TextLen: Integer;
        SepLen: Integer;
        DecimalPlaces: Integer;
        GroupSeparator: Text[30];
        GroupSeparatorCount: Integer;
        LeadingZero: Text;
        i: Integer;
        DateText: Boolean;
    begin
        // The Application Identifiers are as defined in http://www.gs1uk.org/downloads/standards/GS1%20General%20%20Specifications.pdf
        // issue 1 Jan 2010. The standard Group Separator is ASCII 29. Symbol scanner LS2208 does not pass this to NAV, but can be
        // set to pass a printable character instead (] has been chosen).

        GroupSeparator := ']';
        GroupSeparator[2] := 29;
        GroupSeparatorCount := 2;

        pos := 1;
        if CopyStr(_FullBarcode, pos, 1) = ']' then begin
            pos := pos + 1;
            case CopyStr(_FullBarcode, pos, 2) of
                'C1':
                    begin
                        pos := pos + 2;
                        while pos <= StrLen(_FullBarcode) do begin
                            IdLen := 0;
                            DecimalPlaces := 0;
                            DateText := false;
                            case CopyStr(_FullBarcode, pos, 2) of
                                '00':
                                    begin
                                        IdLen := 2;
                                        TextLen := 18;
                                        SepLen := 0;
                                    end;
                                '01':
                                    begin
                                        IdLen := 2;
                                        TextLen := 14;
                                        SepLen := 0;
                                    end;
                                '02':
                                    begin
                                        IdLen := 2;
                                        TextLen := 14;
                                        SepLen := 0;
                                    end;
                                '10':
                                    begin
                                        IdLen := 2;
                                        TextLen := 20;
                                        FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                    end;
                                '11':
                                    begin
                                        IdLen := 2;
                                        TextLen := 6;
                                        SepLen := 0;
                                        DateText := true;
                                    end;
                                '12':
                                    begin
                                        IdLen := 2;
                                        TextLen := 6;
                                        SepLen := 0;
                                        DateText := true;
                                    end;
                                '13':
                                    begin
                                        IdLen := 2;
                                        TextLen := 6;
                                        SepLen := 0;
                                        DateText := true;
                                    end;
                                '15':
                                    begin
                                        IdLen := 2;
                                        TextLen := 6;
                                        SepLen := 0;
                                        DateText := true;
                                    end;
                                '17':
                                    begin
                                        IdLen := 2;
                                        TextLen := 6;
                                        SepLen := 0;
                                        DateText := true;
                                    end;
                                '20':
                                    begin
                                        IdLen := 2;
                                        TextLen := 2;
                                        SepLen := 0;
                                    end;
                                '21':
                                    begin
                                        IdLen := 2;
                                        TextLen := 20;
                                        FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                    end;
                                '22':
                                    begin
                                        IdLen := 2;
                                        TextLen := 29;
                                        FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                    end;
                                '30':
                                    begin
                                        IdLen := 2;
                                        TextLen := 8;
                                        FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                    end;
                                '37':
                                    begin
                                        IdLen := 2;
                                        TextLen := 8;
                                        FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                    end;
                                '90' .. '99':
                                    begin
                                        IdLen := 2;
                                        TextLen := 30;
                                        FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                    end;
                                '24':
                                    case CopyStr(_FullBarcode, pos + 2, 1) of
                                        '0':
                                            begin
                                                IdLen := 3;
                                                TextLen := 30;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '1':
                                            begin
                                                IdLen := 3;
                                                TextLen := 30;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '2':
                                            begin
                                                IdLen := 3;
                                                TextLen := 6;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                    end;
                                '25':
                                    case CopyStr(_FullBarcode, pos + 2, 1) of
                                        '0':
                                            begin
                                                IdLen := 3;
                                                TextLen := 30;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '1':
                                            begin
                                                IdLen := 3;
                                                TextLen := 30;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '3':
                                            begin
                                                IdLen := 3;
                                                TextLen := 30;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '4':
                                            begin
                                                IdLen := 3;
                                                TextLen := 20;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                    end;
                                '40':
                                    case CopyStr(_FullBarcode, pos + 2, 1) of
                                        '0':
                                            begin
                                                IdLen := 3;
                                                TextLen := 30;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '1':
                                            begin
                                                IdLen := 3;
                                                TextLen := 30;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '2':
                                            begin
                                                IdLen := 3;
                                                TextLen := 17;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '3':
                                            begin
                                                IdLen := 3;
                                                TextLen := 30;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                    end;
                                '41':
                                    case CopyStr(_FullBarcode, pos + 2, 1) of
                                        '0' .. '5':
                                            begin
                                                IdLen := 3;
                                                TextLen := 13;
                                                SepLen := 0;
                                            end;
                                    end;
                                '42':
                                    case CopyStr(_FullBarcode, pos + 2, 1) of
                                        '0':
                                            begin
                                                IdLen := 3;
                                                TextLen := 20;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '1':
                                            begin
                                                IdLen := 3;
                                                TextLen := 9;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '2':
                                            begin
                                                IdLen := 3;
                                                TextLen := 3;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '3':
                                            begin
                                                IdLen := 3;
                                                TextLen := 15;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '4':
                                            begin
                                                IdLen := 3;
                                                TextLen := 3;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                        '5':
                                            begin
                                                IdLen := 3;
                                                TextLen := 3;
                                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                            end;
                                    end;
                                '31' .. '36':
                                    if pos + 3 <= StrLen(_FullBarcode) then begin
                                        IdLen := 4;
                                        TextLen := 6;
                                        SepLen := 0;
                                        Evaluate(DecimalPlaces, CopyStr(_FullBarcode, pos + 3, 1));
                                    end;
                                '39':
                                    if pos + 3 <= StrLen(_FullBarcode) then begin
                                        IdLen := 4;
                                        Evaluate(DecimalPlaces, CopyStr(_FullBarcode, pos + 3, 1));
                                        case CopyStr(_FullBarcode, pos + 2, 1) of
                                            '0':
                                                begin
                                                    TextLen := 15;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '1':
                                                begin
                                                    TextLen := 18;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '2':
                                                begin
                                                    TextLen := 15;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '3':
                                                begin
                                                    TextLen := 18;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            else
                                                IdLen := 0;
                                        end;
                                    end;
                                '70':
                                    begin
                                        IdLen := 4;
                                        case CopyStr(_FullBarcode, pos + 2, 2) of
                                            '01':
                                                begin
                                                    TextLen := 13;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '02':
                                                begin
                                                    TextLen := 30;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '03':
                                                begin
                                                    TextLen := 10;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '04':
                                                begin
                                                    TextLen := 4;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '3s':
                                                begin
                                                    TextLen := 30;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            else
                                                IdLen := 0;
                                        end;
                                    end;
                                '80':
                                    begin
                                        IdLen := 4;
                                        case CopyStr(_FullBarcode, pos + 2, 2) of
                                            '01':
                                                begin
                                                    TextLen := 14;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '02':
                                                begin
                                                    TextLen := 20;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '03':
                                                begin
                                                    TextLen := 30;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '04':
                                                begin
                                                    TextLen := 30;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '05':
                                                begin
                                                    TextLen := 6;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '06':
                                                begin
                                                    TextLen := 18;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '07':
                                                begin
                                                    TextLen := 30;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '08':
                                                begin
                                                    TextLen := 12;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '18':
                                                begin
                                                    TextLen := 18;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '20':
                                                begin
                                                    TextLen := 25;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            else
                                                IdLen := 0;
                                        end;
                                    end;
                                '81':
                                    begin
                                        IdLen := 4;
                                        case CopyStr(_FullBarcode, pos + 2, 2) of
                                            '00':
                                                begin
                                                    TextLen := 6;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '01':
                                                begin
                                                    TextLen := 10;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '02':
                                                begin
                                                    TextLen := 2;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            '10':
                                                begin
                                                    TextLen := 30;
                                                    FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                                                end;
                                            else
                                                IdLen := 0;
                                        end;
                                    end;
                            end;
                            if IdLen > 0 then begin
                                count := count + 1;
                                if IdLen > 0 then
                                    _BarCodeArray[count, 1] := CopyStr(_FullBarcode, pos, IdLen)
                                else
                                    _BarCodeArray[count, 1] := '';
                                if TextLen > 0 then begin
                                    _BarCodeArray[count, 2] := CopyStr(_FullBarcode, pos + IdLen, TextLen);

                                    if DecimalPlaces > 0 then
                                        if DecimalPlaces < TextLen then
                                            _BarCodeArray[count, 2] := CopyStr(_BarCodeArray[count, 2], 1, TextLen - DecimalPlaces) + '.' +
                                                                      CopyStr(_BarCodeArray[count, 2], TextLen - DecimalPlaces + 1)
                                        else begin
                                            LeadingZero := '0.';
                                            if DecimalPlaces > TextLen then
                                                for i := 1 to DecimalPlaces - TextLen do
                                                    LeadingZero := LeadingZero + '0';
                                            _BarCodeArray[count, 2] := LeadingZero + _BarCodeArray[count, 2];
                                        end;

                                    if DateText then begin
                                        _BarCodeArray[count, 2] := CopyStr(_BarCodeArray[count, 2], 5, 2) +
                                                                  CopyStr(_BarCodeArray[count, 2], 3, 2) +
                                                                  CopyStr(_BarCodeArray[count, 2], 1, 2);
                                        if CopyStr(_BarCodeArray[count, 2], 1, 2) = '00' then
                                            _BarCodeArray[count, 2] := '01' + CopyStr(_BarCodeArray[count, 2], 3);
                                    end;
                                end else
                                    _BarCodeArray[count, 2] := '';
                            end else begin
                                TextLen := StrLen(_FullBarcode) - pos - IdLen + 1;
                                FindSeparator(_FullBarcode, pos, IdLen, GroupSeparator, GroupSeparatorCount, TextLen, TextLen, SepLen);
                            end;
                            pos := pos + IdLen + TextLen + SepLen;
                        end;
                    end;
                else begin
                    pos := pos + 2;
                    IdLen := 0;
                    TextLen := StrLen(_FullBarcode) - pos - IdLen + 1;
                    SepLen := 0;

                    count := count + 1;
                    if IdLen > 0 then
                        _BarCodeArray[count, 1] := CopyStr(_FullBarcode, pos, IdLen)
                    else
                        _BarCodeArray[count, 1] := '';
                    if TextLen > 0 then
                        _BarCodeArray[count, 2] := CopyStr(_FullBarcode, pos + IdLen, TextLen)
                    else
                        _BarCodeArray[count, 2] := '';
                end;
            end;
        end else begin
            IdLen := 0;
            TextLen := StrLen(_FullBarcode) - pos - IdLen + 1;
            SepLen := 0;

            count := count + 1;
            if IdLen > 0 then
                _BarCodeArray[count, 1] := CopyStr(_FullBarcode, pos, IdLen)
            else
                _BarCodeArray[count, 1] := '';
            if TextLen > 0 then
                _BarCodeArray[count, 2] := CopyStr(_FullBarcode, pos + IdLen, TextLen)
            else
                _BarCodeArray[count, 2] := '';
        end;
    end;

    procedure FindSeparator(_FullBarcode: Text; _Position: Integer; _IdentifierLength: Integer; _Separators: Text[100]; _SeparatorCount: Integer; _MaxLength: Integer; var _TextLength: Integer; var _SeparatorLength: Integer)
    var
        i: Integer;
    begin
        _SeparatorLength := 0;
        i := 0;
        while (i < _SeparatorCount) and (_SeparatorLength = 0) do begin
            i := i + 1;
            _TextLength := STRPOS(CopyStr(_FullBarcode, _Position), CopyStr(_Separators, i, 1));
            if _TextLength > _IdentifierLength then begin
                _TextLength := _TextLength - _IdentifierLength - 1;
                _SeparatorLength := 1;
            end;
        end;

        if _SeparatorLength = 0 then
            _TextLength := StrLen(_FullBarcode) - _Position - _IdentifierLength + 1;

        if (_TextLength > _MaxLength) and (_MaxLength > 0) then
            _TextLength := _MaxLength;
    end;

    procedure ReadEAN(_FullBarCode: Text) _EAN: Text
    var
        BarCodeArray: array[20, 2] of Text;
        i: Integer;
    begin
        _EAN := '';
        Clear(BarCodeArray);

        ReadBarcode(_FullBarCode, BarCodeArray);

        i := 1;
        repeat
            case BarCodeArray[i, 1] of
                '01', '':
                    _EAN := BarCodeArray[i, 2];
            end;
            i := i + 1;
        until (i > ARRAYLEN(BarCodeArray, 1)) or ((BarCodeArray[i, 1] = '') and (BarCodeArray[i, 2] = '')) or (_EAN <> '');
    end;

    procedure ReadLot(_FullBarCode: Text) _Lot: Text
    var
        BarCodeArray: array[20, 2] of Text;
        i: Integer;
    begin
        _Lot := '';
        Clear(BarCodeArray);

        ReadBarcode(_FullBarCode, BarCodeArray);

        i := 1;
        repeat
            case BarCodeArray[i, 1] of
                '10', '':
                    _Lot := BarCodeArray[i, 2];
            end;
            i := i + 1;
        until (i > ARRAYLEN(BarCodeArray, 1)) or ((BarCodeArray[i, 1] = '') and (BarCodeArray[i, 2] = '')) or (_Lot <> '');
    end;

    procedure ReadExpiration(_FullBarCode: Text) _Expiration: Date
    var
        BarCodeArray: array[20, 2] of Text;
        i: Integer;
    begin
        _Expiration := 0D;
        Clear(BarCodeArray);

        ReadBarcode(_FullBarCode, BarCodeArray);

        i := 1;
        repeat
            case BarCodeArray[i, 1] of
                '17':
                    Evaluate(_Expiration, BarCodeArray[i, 2]);
                '':
                    begin
                        if StrLen(BarCodeArray[i, 2]) = 6 then begin
                            BarCodeArray[i, 2] := CopyStr(BarCodeArray[i, 2], 5, 2) +
                                                  CopyStr(BarCodeArray[i, 2], 3, 2) +
                                                  CopyStr(BarCodeArray[i, 2], 1, 2);
                            if CopyStr(BarCodeArray[i, 2], 1, 2) = '00' then
                                BarCodeArray[i, 2] := '01' + CopyStr(BarCodeArray[i, 2], 3);
                        end;
                        Evaluate(_Expiration, BarCodeArray[i, 2]);
                    end;
            end;
            i := i + 1;
        until (i > ARRAYLEN(BarCodeArray, 1)) or ((BarCodeArray[i, 1] = '') and (BarCodeArray[i, 2] = '')) or (_Expiration <> 0D);
    end;

    procedure ReadBestBefore(_FullBarCode: Text) _BestBefore: Date
    var
        BarCodeArray: array[20, 2] of Text;
        i: Integer;
    begin
        _BestBefore := 0D;
        Clear(BarCodeArray);

        ReadBarcode(_FullBarCode, BarCodeArray);

        i := 1;
        repeat
            case BarCodeArray[i, 1] of
                '15':
                    Evaluate(_BestBefore, BarCodeArray[i, 2]);
                '':
                    begin
                        if StrLen(BarCodeArray[i, 2]) = 6 then begin
                            BarCodeArray[i, 2] := CopyStr(BarCodeArray[i, 2], 5, 2) +
                                                  CopyStr(BarCodeArray[i, 2], 3, 2) +
                                                  CopyStr(BarCodeArray[i, 2], 1, 2);
                            if CopyStr(BarCodeArray[i, 2], 1, 2) = '00' then
                                BarCodeArray[i, 2] := '01' + CopyStr(BarCodeArray[i, 2], 3);
                        end;
                        Evaluate(_BestBefore, BarCodeArray[i, 2]);
                    end;
            end;
            i := i + 1;
        until (i > ARRAYLEN(BarCodeArray, 1)) or ((BarCodeArray[i, 1] = '') and (BarCodeArray[i, 2] = '')) or (_BestBefore <> 0D);
    end;

    procedure ReadVariant(_FullBarCode: Text) Variant: Text
    var
        BarCodeArray: array[20, 2] of Text;
        i: Integer;
    begin
        Variant := '';
        Clear(BarCodeArray);

        ReadBarcode(_FullBarCode, BarCodeArray);

        i := 1;
        repeat
            case BarCodeArray[i, 1] of
                '20', '':
                    Variant := BarCodeArray[i, 2];
            end;
            i := i + 1;
        until (i > ARRAYLEN(BarCodeArray, 1)) or ((BarCodeArray[i, 1] = '') and (BarCodeArray[i, 2] = '')) or (Variant <> '');
    end;

    procedure ReadSerial(_FullBarCode: Text) _Serial: Text
    var
        BarCodeArray: array[20, 2] of Text;
        i: Integer;
    begin
        _Serial := '';
        Clear(BarCodeArray);

        ReadBarcode(_FullBarCode, BarCodeArray);

        i := 1;
        repeat
            case BarCodeArray[i, 1] of
                '21', '':
                    _Serial := BarCodeArray[i, 2];
            end;
            i := i + 1;
        until (i > ARRAYLEN(BarCodeArray, 1)) or ((BarCodeArray[i, 1] = '') and (BarCodeArray[i, 2] = '')) or (_Serial <> '');
    end;

    procedure ReadBin(_FullBarCode: Text) _Bin: Text
    var
        BarCodeArray: array[20, 2] of Text;
        i: Integer;
    begin
        _Bin := '';
        Clear(BarCodeArray);

        ReadBarcode(_FullBarCode, BarCodeArray);

        i := 1;
        repeat
            case BarCodeArray[i, 1] of
                //'','': Old code
                '': // New code
                    _Bin := BarCodeArray[i, 2];
            end;
            i := i + 1;
        until (i > ARRAYLEN(BarCodeArray, 1)) or ((BarCodeArray[i, 1] = '') and (BarCodeArray[i, 2] = '')) or (_Bin <> '');
    end;

    procedure ReadMisc(_FullBarCode: Text) _BarCode: Text
    var
        BarCodeArray: array[20, 2] of Text;
        i: Integer;
    begin
        _BarCode := '';
        Clear(BarCodeArray);

        ReadBarcode(_FullBarCode, BarCodeArray);

        i := 1;
        repeat
            case BarCodeArray[i, 1] of
                //'','': Old
                '': //New
                    _BarCode := BarCodeArray[i, 2];
            end;
            i := i + 1;
        until (i > ARRAYLEN(BarCodeArray, 1)) or ((BarCodeArray[i, 1] = '') and (BarCodeArray[i, 2] = '')) or (_BarCode <> '');
    end;

    //
    // ----- MISC. -----
    //

    procedure DelStrCRLFHT(_Text: Text): Text
    var
        TrimmedText: Text;
        CR: Char;
        LF: Char;
        HT: Char;
    begin
        CR := 13;
        LF := 10;
        HT := 9;

        TrimmedText := DelChr(_Text, '=', CR);
        TrimmedText := DelChr(TrimmedText, '=', LF);
        TrimmedText := DelChr(TrimmedText, '=', HT);
        while StrPos(TrimmedText, '  ') <> 0 do // XmlDom writing CDATA partially with double spaces instead of Horizontal Tab
            TrimmedText := DelStr(TrimmedText, StrPos(TrimmedText, '  '), 2);

        exit(TrimmedText);
    end;

    /// <summary>
    /// Convert Mobile Response boolean to BC boolean
    /// </summary>    
    procedure Text2Boolean(_BooleanText: Text) _ReturnValue: Boolean
    begin
        if _BooleanText = '' then
            _ReturnValue := false
        else
            Evaluate(_ReturnValue, _BooleanText);
    end;

    /// <summary>
    /// Convert Mobile Response (dd-MM-yyyy) formatted date-value to Date
    /// </summary>    
    procedure Text2Date(_DateText: Text): Date;
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        if Evaluate(Day, CopyStr(_DateText, 1, 2)) and
           Evaluate(Month, CopyStr(_DateText, 4, 2)) and
           Evaluate(Year, CopyStr(_DateText, 7, 4))
        then
            exit(DMY2Date(Day, Month, Year));
    end;

    /// <summary>
    /// Convert Mobile Response (dd-MM-yyyy mm:hh:ss) formatted datetime-value to DateTime
    /// </summary>    
    procedure Text2DateTime(_Text: Text) _ReturnValue: DateTime;
    var
        TempDate: Date;
        TempTime: Time;
    begin
        TempDate := Text2Date(CopyStr(_Text, 1, 10));

        if Evaluate(TempTime, CopyStr(_Text, 12, 8)) then
            _ReturnValue := CreateDateTime(TempDate, TempTime);
    end;

    /// <summary>
    /// Convert Mobile Response Decimal to NAV Decimal
    /// </summary>
    procedure Text2Decimal(_Text: Text) _ReturnValue: Decimal
    begin
        if Evaluate(_ReturnValue, _Text, 9) then
            exit(_ReturnValue);
    end;

    /// <summary>
    /// Convert Mobile Response Integer to NAV Integer
    /// </summary>
    procedure Text2Integer(_Text: Text) _ReturnValue: Integer
    begin
        if Evaluate(_ReturnValue, _Text, 9) then
            exit(_ReturnValue);
    end;

    /// <summary>
    /// Convert Text to a valid Xml Node-name (remove illegal chars)
    /// </summary>
    [Obsolete('Unused in standard Mobile WMS  (planned for removal 04/2024)', 'MOB5.39')]
    procedure Text2XmlNodeName(_InText: Text): Text
    begin
        exit(TextRemoveNotInCharset(_InText, CharsetAlphaNumeric()));
    end;

    /// <summary>
    /// Remove chars not present in a charset
    /// </summary>
    /// <param name="_Text">Input text</param>
    /// <param name="_LegalCharset">List of legal characters</param>
    internal procedure TextRemoveNotInCharset(_Text: Text; _LegalCharset: Text) ReturnResult: Text
    var
        IllegalChars: Text;
    begin
        IllegalChars := DelChr(_Text, '=', _LegalCharset);
        ReturnResult := DelChr(_Text, '=', IllegalChars);
        exit(ReturnResult);
    end;

    /// <summary>
    /// Url Encode text
    /// </summary>
    procedure Text2UrlEncodedText(var _Text: Text)
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        TypeHelper.UrlEncode(_Text);
    end;

    procedure Format2Text1024(_Input: Variant): Text[1024]
    begin
        exit(CopyStr(Format(_Input), 1, 1024));
    end;

    internal procedure ConvertGUIDtoCode100(_Value: Guid) ReturnValue: Code[100]
    begin
        ReturnValue := _Value;
        ReturnValue := DelChr(ReturnValue, '=', '{}');
    end;

    /// <summary>
    /// Is _Text in Mobile Request DateText format dd-mm-yyyy
    /// </summary>
    procedure IsDateText(_Text: Text): Boolean
    VAR
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        if StrLen(_Text) <> StrLen('DD-MM-YYYY') then
            exit(false);

        exit(Evaluate(Day, CopyStr(_Text, 1, 2)) and
             Evaluate(Month, CopyStr(_Text, 4, 2)) and
             Evaluate(Year, CopyStr(_Text, 7, 4)) and
             (_Text[3] = '-') and
             (_Text[6] = '-'));
    end;

    /// <summary>
    /// Is _Expression a filter (as opposed to a direct value)
    /// </summary>   
    procedure IsFilter(_Expression: Text): Boolean
    begin
        exit(
           StrPos(_Expression, '..') +
           StrPos(_Expression, '|') +
           StrPos(_Expression, '<') +
           StrPos(_Expression, '>') +
           StrPos(_Expression, '&') +
           StrPos(_Expression, '?') +
           StrPos(_Expression, '*') +
           StrPos(_Expression, '=') > 0);
    end;

    /// <summary>
    /// Is _Expression a valid expression for the _MaxStrLen.
    /// The expression may include a partial expression that exceeds _MaxStrLen but we allow code to run in this case and the SetRange/SetFilter will display an error
    /// </summary>   
    procedure IsValidExpressionLen(_Expression: Text; _MaxStrLen: Integer): Boolean
    begin
        if StrLen(_Expression) <= _MaxStrLen then
            exit(true);

        exit(IsFilter(_Expression));  // Allow _Expressions exceeding _MaxStrLen only when expression is a filter
    end;

    /// <summary>
    /// Convert Decimal to Text in Mobile Display format (Mobile user language format)
    /// </summary>   
    procedure FormatDecimal2Text(_Decimal: Decimal; _BlankZero: boolean): Text
    begin
        if (_Decimal = 0) and _BlankZero then
            exit(' ') // Space is intentional
        else
            exit(Format(_Decimal));
    end;

    procedure DecimalTextXmlFormat2Decimal(_XmlValue: Text) _ReturnValue: Decimal
    begin
        // This function returns a Decimal based on the Xml text format
        Evaluate(_ReturnValue, _XmlValue, 9);
    end;

    /// <summary>
    /// Replaces filename in path with another name i.e. "path/folder/filename.txt"
    /// </summary>
    internal procedure PathHelperReplaceFileName(_Path: Text; _NewFileName: Text; var _ReturnPath: Text) Success: Boolean
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
        FileNamePos: Integer;
    begin
        FileName := FileManagement.GetFileNameWithoutExtension(_Path);
        FileNamePos := StrPos(_Path, FileName);
        if FileNamePos = 0 then exit;
        _ReturnPath := CopyStr(_Path, 1, FileNamePos - 1) +
                        _NewFileName +
                        CopyStr(_Path, FileNamePos + StrLen(FileName));
        exit(true);
    end;

    procedure Add_GS1Ai(var _GS1AiText: Text; _AddValue: Text)
    begin
        if _GS1AiText = '' then
            _GS1AiText := _AddValue
        else
            if _AddValue <> '' then
                _GS1AiText := _GS1AiText + ',' + _AddValue;
    end;

    /// <summary>
    /// Read and possibly split "BackendID" from mobile request into
    /// - BC Order No.
    /// - Prefix. Source document type, SO, PO, TR (If present)
    ///</summary>
    procedure GetOrderAndPrefixFromBackendID(_BackendID: Text; var _OrderNo: Code[20]; var _Prefix: Code[20])
    var
        Pos: Integer;
    begin
        // BackendID is prefiex like 'I-12345678901234567890' or 'SO-12345678901234567890'
        // Split the fields
        if StrLen(_BackendID) > MaxStrLen(_OrderNo) then begin
            Pos := StrPos(_BackendID, '-');

            if Pos > 0 then begin
                _OrderNo := CopyStr(_BackendID, Pos + 1);
                _PreFix := CopyStr(_BackendID, 1, Pos);
            end else
                _OrderNo := _BackendID;
        end else
            // BackendID is not prefixed, use as it is
            _OrderNo := _BackendID;
    end;

    /// <summary>
    /// Adds text to List of Texts (if not already added) 
    /// </summary>
    /// <param name="_List">The resulting List of Texts</param>
    /// <param name="_Text">Text to add</param>
    procedure AddUniqueText(var _List: List of [Text]; _Text: Text)
    begin
        if not _List.Contains(_Text) then
            _List.Add(_Text);
    end;

    /// <summary>
    /// Set GlobalLanguage
    /// </summary>
    /// <param name="_LanguageCode">I.e.'ENU'</param>
    internal procedure SetGlobalLanguage(_LanguageCode: Code[10])
    var
        Language: Record "Language";
    begin
        if Language.Get(_LanguageCode) then begin
            Language.TestField("Windows Language ID");  // Invalid setup = must error
            GlobalLanguage(Language."Windows Language ID");
        end;
    end;

    /// <summary>
    /// Get current GlobalLanguage language code
    /// Language must exist in base language table
    /// </summary>
    /// <returns>Current language as Language Code i.e. 'ENU'</returns>
    internal procedure GetGlobalLanguage() _ReturnLanguageCode: Code[10]
    var
        Language: Record "Language";
    begin
        Language.SetRange("Windows Language ID", GlobalLanguage());
        if Language.FindFirst() then
            exit(Language.Code);
    end;

    //
    // ----- CONSTANTS -----
    //

    procedure GetItemNoGS1Ai() _ItemNoGS1Ai: Text
    begin
        _ItemNoGS1Ai := ItemNoGS1AiTxt;
        OnAfterGetItemNoGS1Ai(_ItemNoGS1Ai);
        exit(_ItemNoGS1Ai);
    end;

    procedure GetLotNoGS1Ai() _LotNoGS1Ai: Text
    begin
        _LotNoGS1Ai := LotNoGS1AiTxt;
        OnAfterGetLotNoGS1Ai(_LotNoGS1Ai);
        exit(_LotNoGS1Ai);
    end;

    procedure GetSerialNoGS1Ai() _SerialNoGS1Ai: Text
    begin
        _SerialNoGS1Ai := SerialNoGS1AiTxt;
        OnAfterGetSerialNoGS1Ai(_SerialNoGS1Ai);
        exit(_SerialNoGS1Ai);
    end;

    procedure GetPackageNoGS1Ai() _PackageNoGS1Ai: Text
    begin
        _PackageNoGS1Ai := PackageNoGS1AiTxt;
        OnAfterGetPackageNoGS1Ai(_PackageNoGS1Ai);
        exit(_PackageNoGS1Ai);
    end;

    procedure GetExpirationDateGS1Ai() _ExpirationDateGS1Ai: Text
    begin
        _ExpirationDateGS1Ai := ExpirationDateGS1AiTxt;
        OnAfterGetExpirationDateGS1Ai(_ExpirationDateGS1Ai);
        exit(_ExpirationDateGS1Ai);
    end;

    procedure GetBinGS1Ai() BinGS1Ai: Text
    begin
        BinGS1Ai := BinGS1AiTxt;
        OnAfterGetBinGS1Ai(BinGS1Ai);
        exit(BinGS1Ai);
    end;

    procedure GetQuantityGS1Ai() _QuantityGS1Ai: Text
    begin
        _QuantityGS1Ai := QuantityGS1AiTxt;
        OnAfterGetQuantityGS1Ai(_QuantityGS1Ai);
        exit(_QuantityGS1Ai);
    end;

    internal procedure CharsetAlphaNumeric(): Text
    begin
        exit('abcdefghijklmnopqrstuvwxyzæøåABCDEFGHIJKLMNOPQRSTUVWXYZÆØÅ0123456789');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemNoGS1Ai(var _ItemNoGS1Ai: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLotNoGS1Ai(var _LotNoGS1Ai: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSerialNoGS1Ai(var _SerialNoGS1Ai: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPackageNoGS1Ai(var _PackageNoGS1Ai: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetExpirationDateGS1Ai(var _ExpirationDateGS1Ai: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBinGS1Ai(var _BinGS1Ai: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetQuantityGS1Ai(var _QuantityGS1Ai: Text)
    begin
    end;
}

