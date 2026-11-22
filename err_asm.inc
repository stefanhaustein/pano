{ err_asm.inc - Scan ez80asm console output via VDP and format standardized error lines }

{$l scrchar.asm}

function ScrChar(X, Y: Integer): Char; register; external '__scrchar';

function ReadScreenRow(Row, MaxCols: Integer): String;
var
  Col, Spaces: Integer;
  Ch: Char;
  S: String;
begin
  Ch := ScrChar(0, Row);
  if (Ch = ' ') or (Ch = #0) then
  begin
    ReadScreenRow := '';
    Exit;
  end;

  S := '';
  Spaces := 0;
  for Col := 0 to MaxCols - 1 do
  begin
    if Col > 0 then Ch := ScrChar(Col, Row);
    if Ch = #0 then Ch := ' ';
    if Ch = ' ' then
    begin
      Inc(Spaces);
      if Spaces > 3 then Break;
    end
    else
      Spaces := 0;
    if Length(S) < 255 then
      S := S + Ch;
  end;

  while (Length(S) > 0) and (S[Length(S)] = ' ') do
    Delete(S, Length(S), 1);
  ReadScreenRow := S;
end;

function FormatEz80AsmError(LineStr: String): String;
var
  P, Q, LineNumEnd: Integer;
  ErrFile, LineNumS, ErrMsg: String;
begin
  FormatEz80AsmError := '';

  { Expected format: File "<name>" line <num> - <msg> }
  if Copy(LineStr, 1, 6) = 'File "' then
  begin
    Delete(LineStr, 1, 6);
    Q := Pos('"', LineStr);
    if Q = 0 then Exit;
    ErrFile := Copy(LineStr, 1, Q - 1);
    Delete(LineStr, 1, Q);

    P := Pos('line ', LineStr);
    if P = 0 then Exit;
    Delete(LineStr, 1, P + 4);

    LineNumEnd := 1;
    while (LineNumEnd <= Length(LineStr)) and
          (LineStr[LineNumEnd] >= '0') and (LineStr[LineNumEnd] <= '9') do
      Inc(LineNumEnd);
    if LineNumEnd = 1 then Exit;
    LineNumS := Copy(LineStr, 1, LineNumEnd - 1);

    P := Pos(' - ', LineStr);
    if P > 0 then
      ErrMsg := Copy(LineStr, P + 3, 255)
    else
      ErrMsg := Copy(LineStr, LineNumEnd, 255);

    FormatEz80AsmError := '*** Error at ' + ErrFile + '(' + LineNumS + ',1): ' + ErrMsg;
    Exit;
  end;

  if Copy(LineStr, 1, 5) = 'Error' then
    FormatEz80AsmError := '*** Error: ' + LineStr;
end;

procedure CaptureAsmErrors(var ErrEntry: String);
var
  Row, LastRow, MaxCols: Integer;
  LineStr, Parsed, Fallback: String;
begin
  ErrEntry := '';
  Fallback := '';
  MaxCols := ScreenWidth;
  if MaxCols > 80 then MaxCols := 80;
  LastRow := WhereY - 1;
  if LastRow < 0 then Exit;
  if LastRow >= ScreenHeight then LastRow := ScreenHeight - 1;

  for Row := LastRow downto 0 do
  begin
    LineStr := ReadScreenRow(Row, MaxCols);
    if LineStr <> '' then
    begin
      Parsed := FormatEz80AsmError(LineStr);
      if Parsed <> '' then
      begin
        if Copy(Parsed, 1, 13) = '*** Error at ' then
        begin
          ErrEntry := Parsed;
          Exit;
        end
        else if Fallback = '' then
          Fallback := Parsed;
      end;
    end;
  end;
  ErrEntry := Fallback;
end;
