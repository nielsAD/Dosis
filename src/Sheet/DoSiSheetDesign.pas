{
  Author: Niels A.D.
  Project: DoSiS (https://github.com/nielsAD/Dosis)
  License: GNU Lesser GPL (http://www.gnu.org/licenses/lgpl.html)

  WebBrowser for property sheet
}
unit DoSiSheetDesign;

interface

uses
  SysUtils, Types, Windows, Forms, Dialogs, Controls, Classes, OleCtrls, ActiveX, SHDocVw,
  DoSiSheet, CustomProtocol, WBNulContainer, DocHostUIHandler;

type
  TWBContainer = class(TNulWBContainer, IDocHostUIHandler, IOleClientSite)
  private
    FExternal: IDispatch;
  protected
    function ShowContextMenu(const dwID: DWORD; const ppt: PPOINT; const pcmdtReserved: IUnknown; const pdispReserved: IDispatch): HResult; stdcall;
    function GetHostInfo(var pInfo: TDocHostUIInfo): HResult; stdcall;
    function GetExternal(out ppDispatch: IDispatch): HResult; stdcall;
  public
    constructor Create(const HostedBrowser: TWebBrowser; const ExternalObj: IDispatch);
    procedure ExecJS(const JavasScript: String);

    property ExternalDispatch: IDispatch write FExternal;
  end;

  TDoSiSheetContent = class(TForm)
    wb: TWebBrowser;
    function pcbLog(const Args: TStringDynArray; var MIMEType: string; const Stream: TCustomMemoryStream): Boolean;
    function pcbFile(const Args: TStringDynArray; var MIMEType: string; const Stream: TCustomMemoryStream): Boolean;
  private
    FWBContainer: TWBContainer;
    function ProtocolHandler(aURL: string; var aMIMEType: string; const aPostMIMEType: string; const aPostData: TByteArray; aMemoryStream: TCustomMemoryStream): Boolean;
  protected
    FFileNames: TFileNameArray;
    function GetExternal: IDispatch; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function InitFileList(FileNames: TFileNameArray): Boolean; virtual;
    property FileNames: TFileNameArray read FFileNames;
  end;

  TDoSiSheetContentManager = class(TInterfacedObject, IDoSiSheetContent)
  protected
    FContent: TDoSiSheetContent;
    FTitle: string;

    procedure OnContentDestroy(Sender: TObject);
    function InitDialog(hDlg: HWND): NativeBool; virtual;

    function GetTitle: string; virtual;
    function Apply(OK: Boolean): NativeBool; virtual;
    function Reset: NativeBool; virtual;
    function Cancel: NativeBool; virtual;
    procedure Resize(NewWidth, NewHeight: Integer); virtual;
  public
    constructor Create(AContent: TDoSiSheetContent; ATitle: string = 'DoSiS');
    destructor Destroy; override;

    property Content: TDoSiSheetContent read FContent;
    property Title: string read GetTitle;
  end;

implementation

uses
  MSHTML, IOUtils, StrUtils, IdGlobalProtocols, IdURI;

{$R *.dfm}

//TWBContainer code based on examples from P D Johnson (delphidabbler.com/articles?article=18)
function TWBContainer.GetHostInfo(var pInfo: TDocHostUIInfo): HResult;
begin
  pInfo.dwFlags := pInfo.dwFlags or DOCHOSTUIFLAG_DIALOG or DOCHOSTUIFLAG_NO3DBORDER;
  Result := S_OK;
end;

function TWBContainer.ShowContextMenu(const dwID: DWORD; const ppt: PPOINT; const pcmdtReserved: IInterface; const pdispReserved: IDispatch): HResult;
begin
  Result := S_OK;
end;

function TWBContainer.GetExternal(out ppDispatch: IDispatch): HResult;
begin
  if (FExternal = nil) then
    Result := inherited GetExternal(ppDispatch)
  else
  begin
    ppDispatch := FExternal;
    Result := S_OK;
  end;
end;

constructor TWBContainer.Create(const HostedBrowser: TWebBrowser; const ExternalObj: IDispatch);
begin
  inherited Create(HostedBrowser);
  FExternal := ExternalObj;
end;

//github.com/jasonpenny/twebbrowser.utilities
procedure TWBContainer.ExecJS(const JavasScript: String);
var
  Doc: IHTMLDocument2;
begin
  if Supports(HostedBrowser.Document, IHTMLDocument2, Doc) then
    Doc.parentWindow.execScript(JavasScript, 'JavaScript');
end;

function TDoSiSheetContent.InitFileList(FileNames: TFileNameArray): Boolean;
begin
  FFileNames := FileNames;
  Result := (Length(FileNames) > 0);
end;

function TDoSiSheetContent.pcbLog(const Args: TStringDynArray; var MIMEType: string; const Stream: TCustomMemoryStream): Boolean;
var
  i: Integer;
begin
  for i := 2 to High(Args) do
    Args[1] := Args[1] + '/' + Args[i];
  ShowMessage('LOG: ' + Args[1]);
  Result := True;
end;

function TDoSiSheetContent.pcbFile(const Args: TStringDynArray; var MIMEType: string; const Stream: TCustomMemoryStream): Boolean;
var
  i: Integer;
  FullPath: string;
  ResourceStream: TStream;
begin
  Result := False;
  if (Length(Args) < 2) then
    Exit;

  for i := 2 to High(Args) do
    Args[1] := Args[1] + '/' + Args[i];

  Args[1] := StringReplace(Args[1], '\\', '/', [rfReplaceAll]);

  try
    FullPath := ExtractFilePath(GetModuleName(hInstance)) + Args[1];
    if FileExists(FullPath) then
      ResourceStream := TFileStream.Create(FullPath, fmOpenRead)
    else
    begin
      FullPath := StringReplace(Args[1],  '/', '_', [rfReplaceAll]);
      FullPath := StringReplace(FullPath, '.', '_', [rfReplaceAll]);
      if (FindResource(hInstance, PChar(Fullpath), RT_RCDATA) = 0) then
        Exit;

      ResourceStream := TResourceStream.Create(hInstance, FullPath, RT_RCData);
    end;
  except
    Exit;
  end;

  try
    Stream.CopyFrom(ResourceStream, ResourceStream.Size);
  finally
    ResourceStream.Free();
  end;

  MIMEType := GetMIMETypeFromFile(Args[1]);
  Result := True;
end;

function TDoSiSheetContent.ProtocolHandler(aURL: string; var aMIMEType: string; const aPostMIMEType: string; const aPostData: TByteArray; aMemoryStream: TCustomMemoryStream): Boolean;
type
  TCallback = function(const Args: TStringDynArray; var MIMEType; const Stream: TCustomMemoryStream): Boolean of object;
var
  i: Integer;
  m: TMethod;
  URL: TStringDynArray;
begin
  Result := False;

  aURL := StringReplace(aURL, '/Interop/', '/', [rfReplaceAll, rfIgnoreCase]);
  aURL := TrimAllOf('/?&', aURL);

  URL := SplitString(aURL, '/');
  for i := Low(URL) to High(URL) do
    URL[i] := TIdURI.URLDecode(URL[i]);

  if (Length(URL) < 2) then
    URL := TStringDynArray.Create('File', aURL);

  m.Code := MethodAddress('pcb' + URL[0]);
  if (m.Code <> nil) then
  begin
    m.Data := Self;
    Result := TCallback(m)(URL, aMimeType, aMemoryStream);
  end;
end;

function TDoSiSheetContent.GetExternal: IDispatch;
begin
  Result := nil;
end;

constructor TDoSiSheetContent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWBContainer := TWBContainer.Create(wb, GetExternal());

  AddProtocolHandler('DoSiS', ProtocolHandler);
end;

destructor TDoSiSheetContent.Destroy;
begin
  EndProtocolHandler();
  FWBContainer.Free();
  inherited Destroy();
end;

constructor TDoSiSheetContentManager.Create(AContent: TDoSiSheetContent; ATitle: string = 'DoSiS');
begin
  inherited Create();

  FContent := AContent;
  FTitle := ATitle;

  if (FContent <> nil) then
    FContent.OnDestroy := OnContentDestroy;
end;

destructor TDoSiSheetContentManager.Destroy;
begin
  if (FContent <> nil) then
    FContent.Free();

  inherited Destroy();
end;

procedure TDoSiSheetContentManager.OnContentDestroy(Sender: TObject);
begin
  if (Sender = FContent) then
    FContent := nil;
end;

function TDoSiSheetContentManager.InitDialog(hDlg: HWND): NativeBool;
var
  NewStyle: NativeInt;
  Rect: TRect;
begin
  if (FContent = nil) then
    Exit(nFalse);

  NewStyle := (GetWindowLong(FContent.Handle, GWL_STYLE) or WS_CHILDWINDOW) and (not WS_POPUP);
  SetWindowLong(FContent.Handle, GWL_STYLE, NewStyle);

  AttachThreadInput(GetCurrentThreadId(), GetWindowThreadProcessId(hDlg), True);
  GetClientRect(hDlg, Rect);

  FContent.ParentWindow := hDlg;
  FContent.BoundsRect := Rect;
  FContent.Visible := True;
  Result := nTrue;
end;

procedure TDoSiSheetContentManager.Resize(NewWidth, NewHeight: Integer);
begin
  if (FContent <> nil) then
    FContent.BoundsRect := TRect.Create(0, 0, NewWidth, NewHeight);
end;

function TDoSiSheetContentManager.GetTitle: string;
begin
  Result := FTitle;
end;

function TDoSiSheetContentManager.Apply(OK: Boolean): NativeBool;
begin
  if OK then
    FContent.Free();
  Result := nFalse;
end;

function TDoSiSheetContentManager.Reset: NativeBool;
begin
  Result := nFalse;
end;

function TDoSiSheetContentManager.Cancel: NativeBool;
begin
  FContent.Free();
  Result := nFalse;
end;

end.
