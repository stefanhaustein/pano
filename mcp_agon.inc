{ mcp_agon.inc - Agon MOSlet resident IDE runner for mcp }

{$i err_asm.inc}
{$l mcposcli.asm}

var
  Dummy: Char;

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

procedure RunIdeLoop;
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
end;
