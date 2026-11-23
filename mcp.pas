program Mcp;

{$A+,U-}

const
  TmpFile = 'PANO.TMP';
  ErrFile = 'PANO.ERR';

type
  TStr80 = String[80];

var
  SrcFile, OutBin, RowS, ColS, Act: TStr80;

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

{$ifdef SYS_AGON}
  {$i mcp_agon.inc}
{$else}
  {$ifdef SYS_CPM}
    {$i mcp_cpm.inc}
  {$else}
    {$error mcp targets Agon MOSlet or CP/M-80.}
  {$endif}
{$endif}

begin
  RunIdeLoop;
end.
