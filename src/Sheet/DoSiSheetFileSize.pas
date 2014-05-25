{
  Author: Niels A.D.
  Project: DoSiS (https://github.com/nielsAD/Dosis)
  License: GNU Lesser GPL (http://www.gnu.org/licenses/lgpl.html)

  TreeMap property sheet
}
unit DoSiSheetFileSize;

interface

uses
  SysUtils, Types, Classes, ComObj,    DIALOGS,
  DoSiS_TLB, DoSiSheet, DoSiSheetDesign, DirectorySizeTree;

type
  TDoSiSheetFileSize = class;

  TDoSiSheetInterop = class(TAutoIntfObject, IInterop, IDispatch)
  private
    FSheet: TDoSiSheetFileSize;
    FMaxChildren: Integer;

    function get_DoSiS: WideString; safecall;
    procedure Set_maxChildren(Value: Integer); safecall;
  public
    constructor Create(ASheet: TDoSiSheetFileSize);
 
    procedure log(const Str: WideString); safecall;
    function getDirectoryTree(const Index: WideString; Depth: Integer): WideString; safecall;
  end;

  TDoSiSheetFileSize = class(TDoSiSheetContent)
    function pcbFileSize(const Args: TStringDynArray; var MIMEType: string; const Stream: TCustomMemoryStream): Boolean;
  protected
    FDirectoryTree: TDirectorySizeTree;
    function GetExternal: IDispatch; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function InitFileList(FileNames: TFileNameArray): Boolean; override;
  end;

implementation

uses
  Forms, ComServ, Windows;

procedure WriteStringToStream(const aStr: string; Stream: TCustomMemoryStream);
var
  utf8Out: UTF8String;
begin
  utf8Out := UTF8Encode(aStr);
  Stream.WriteBuffer(Pointer(utf8Out)^, Length(utf8Out) * SizeOf(AnsiChar));
end;

constructor TDoSiSheetInterop.Create(ASheet: TDoSiSheetFileSize);
begin
  inherited Create(ComServer.TypeLib, IInterop);
  FSheet := ASheet;
  FMaxChildren := -1;
end;

function TDoSiSheetInterop.get_DoSiS: WideString;
var
  Version: Cardinal;  
begin
  Version := GetFileVersion(GetModuleName(HInstance));
  Result := Format('%d.%d', [HiWord(Version), LoWord(Version)]);
end;

procedure TDoSiSheetInterop.Set_maxChildren(Value: Integer);
begin
  FMaxChildren := Value;
end;

procedure TDoSiSheetInterop.log(const Str: WideString);
begin
  ShowMessage(Str);
end;

function TDoSiSheetInterop.getDirectoryTree(const Index: WideString; Depth: Integer): WideString;
var
  Dir: TDirectorySizeTree;
begin
  Result := '';

  if (FSheet = nil) or (FSheet.FDirectoryTree = nil) or (Index = '') or (Index[1] <> 'D') then
    Exit;

  Dir := FSheet.FDirectoryTree.SubDirectoryIndex[Copy(Index, 2)];
  if (Dir = nil) then
    Exit;

  Result := Dir.ToJSON(Depth, FMaxChildren);
end;

function TDoSiSheetFileSize.pcbFileSize(const Args: TStringDynArray; var MIMEType: string; const Stream: TCustomMemoryStream): Boolean;
var
  JSON: string;
  Dir: TDirectorySizeTree;
begin
  Result := False;

  if (FDirectoryTree = nil) or (Length(args) < 2) or (Args[1] = '') or (Args[1][1] <> 'D') then
    Exit;

  Dir := FDirectoryTree.SubDirectoryIndex[Copy(Args[1], 2)];
  if (Dir = nil) then
    Exit;

  if (Length(Args) > 2) and (Args[2] <> '')  then
    JSON := Dir.ToJSON(StrToIntDef(Args[2], 0))
  else
    JSON := Dir.ToJSON();
  
  if (Length(Args) > 3) and (Args[3] <> '') then
  begin
    MIMEType := 'application/javascript';
    WriteStringToStream(Args[3] + '(' + JSON + ');', Stream);
  end
  else
  begin
    MIMEType := 'application/json';
    WriteStringToStream(JSON, Stream);
  end;

  Result := True;
end;

function TDoSiSheetFileSize.GetExternal: IDispatch;
begin
  Result := TDoSiSheetInterop.Create(Self);
end;

constructor TDoSiSheetFileSize.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDirectoryTree := nil;
end;

destructor TDoSiSheetFileSize.Destroy;
begin
  if (FDirectoryTree <> nil) then
    FDirectoryTree.Free();
  inherited Destroy();
end;

function TDoSiSheetFileSize.InitFileList(FileNames: TFileNameArray): Boolean;
begin
  Result := (inherited InitFileList(FileNames)) and
    ((Length(FileNames) > 1) or DirectoryExists(FileNames[0]));

  if Result then
  begin
    FDirectoryTree := TDirectorySizeTree.Create(FileNames);
    wb.Navigate2('DoSiS://Interop/File/TreeMap/index.html');
  end;
end;

function SheetHandler(FileNames: TFileNameArray; out Content: IDoSiSheetContent): Boolean;
var
  Form: TDoSiSheetContent;
begin
  Application.CreateForm(TDoSiSheetFileSize, Form);
  Result := Form.InitFileList(FileNames);

  if Result then
    Content := TDoSiSheetContentManager.Create(Form, 'TreeMap')
  else
    Form.Free();
end;

initialization
  AddSheetHandler(SheetHandler);
finalization
  RemoveSheetHandler(SheetHandler);
end.
