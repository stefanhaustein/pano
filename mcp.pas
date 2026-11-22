program Mcp;

{$ifndef SYS_AGON}
  {$error mcp targets Agon MOSlet.}
{$endif}

{$A+,U-}

const
  TmpFile = 'PANO.TMP';
  ErrFile = 'PANO.ERR';

type
  TStr80 = String[80];

var
  SrcFile, OutBin, RowS, ColS, Act: TStr80;
  Dummy: Char;

{$i err_asm.inc}
{$l mcposcli.asm}

function McpOscli(CmdAddr: Integer): Byte; register; external '__mcp_oscli';

procedure McpExec(Command, Params: TStr80);
var
  Temp: String;
begin
  if Params = '' then
    Temp := Command + #00
  else
    Temp := Command + ' ' + Params + #00;
  DosExitCode := McpOscli(Addr(Temp) + 1);
end;

function FileExists(Name: TStr80): Boolean;
var
  F: File;
  Err: Byte;
begin
  {$I-}
  Assign(F, Name);
  Reset(F);
  Err := IOResult;
  if Err = 0 then
  begin
    Close(F);
    Err := IOResult;
    FileExists := True;
  end
  else
    FileExists := False;
  {$I+}
end;

procedure DeleteIfExists(Name: TStr80);
var
  F: File;
  Err: Byte;
begin
  {$I-}
  Assign(F, Name);
  Erase(F);
  Err := IOResult;
  {$I+}
end;

procedure RunBin(Path, Fallback, Params: TStr80);
begin
  McpExec('load', Path + ' 0x40000');
  if (DosExitCode <> 0) and (Fallback <> '') then
    McpExec('load', Fallback + ' 0x40000');
  if DosExitCode <> 0 then Exit;

  if Params <> '' then
    McpExec('run', '0x40000 ' + Params)
  else
    McpExec('run', '0x40000');
end;

function ReadRequest: Boolean;
var
  T: Text;
  Err: Byte;
begin
  {$I-}
  Assign(T, TmpFile);
  Reset(T);
  Err := IOResult;
  {$I+}
  if Err <> 0 then
  begin
    ReadRequest := False;
    Exit;
  end;

  {$I-}
  ReadLn(T, Act);
  ReadLn(T, SrcFile);
  ReadLn(T, OutBin);
  ReadLn(T, RowS);
  ReadLn(T, ColS);
  Close(T);
  Err := IOResult;
  {$I+}
  ReadRequest := (Err = 0) and (SrcFile <> '');
end;

procedure WriteErrorFile(Line: String);
var
  T: Text;
  Err: Byte;
begin
  {$I-}
  Assign(T, ErrFile);
  Rewrite(T);
  Err := IOResult;
  if Err = 0 then
  begin
    WriteLn(T, Line);
    Close(T);
    Err := IOResult;
  end;
  {$I+}
end;

procedure WriteResult(Status: TStr80);
var
  T: Text;
  Err: Byte;
begin
  {$I-}
  Assign(T, TmpFile);
  Rewrite(T);
  Err := IOResult;
  if Err = 0 then
  begin
    WriteLn(T, Status);
    WriteLn(T, SrcFile);
    WriteLn(T, OutBin);
    WriteLn(T, RowS);
    WriteLn(T, ColS);
    Close(T);
    Err := IOResult;
  end;
  {$I+}
end;

var
  BinOk: Boolean;
  ErrEntry: String;

begin
  if ParamCount >= 1 then
    SrcFile := ParamStr(1)
  else
    SrcFile := '';

  while True do
  begin
    RunBin('/bin/pano.bin', 'pano.bin', SrcFile);
    if DosExitCode <> 0 then
    begin
      WriteLn('Error launching pano.bin (code ', DosExitCode, ')');
      Break;
    end;

    if not ReadRequest then
      Break;

    ClrScr;
    WriteLn('Assembling ', SrcFile, ' -> ', OutBin, '...');
    DeleteIfExists(OutBin);
    DeleteIfExists(ErrFile);
    RunBin('/bin/ez80asm.bin', 'ez80asm.bin', SrcFile + ' ' + OutBin + ' -c');
    BinOk := (DosExitCode = 0) and FileExists(OutBin);

    if BinOk then
    begin
      WriteResult('OK');
      if Act = 'R' then
      begin
        WriteLn;
        WriteLn('Running ', OutBin, '...');
        RunBin(OutBin, '', '');
        WriteLn;
        Write('Press any key to return to pano...');
        Dummy := ReadKey;
      end;
    end
    else
    begin
      CaptureAsmErrors(ErrEntry);
      if ErrEntry <> '' then
        WriteErrorFile(ErrEntry);
      WriteResult('ERR');
      WriteLn;
      WriteLn('Assembly failed.');
    end;
  end;
end.
