{
  Author: Niels A.D.
  Project: DoSiS (https://github.com/nielsAD/Dosis)
  License: GNU Lesser GPL (http://www.gnu.org/licenses/lgpl.html)

  IShellPropSheetExt implementation
}
unit DoSiSheet;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  SysUtils, Windows, ActiveX, ComObj, CommCtrl, ShlObj, StdVcl,
  DoSiS_TLB;

type
  NativeBool = type NativeUInt;
  TFileNameArray = array of TFileName;
 
  IDoSiSheetContent = interface
    function InitDialog(hDlg: HWND): NativeBool;
	  function GetTitle(): string;
    function Apply(OK: Boolean): NativeBool;
    function Reset(): NativeBool;
    function Cancel(): NativeBool;
    procedure Resize(NewWidth, NewHeight: Integer);
  end;

  TDoSiSheet = class(TAutoObject, IDoSiSheet, IShellExtInit, IShellPropSheetExt)
  protected
    function CreateSheetContent: IDoSiSheetContent;
    function Initialize(pidlFolder: PItemIDList; lpdobj: IDataObject; hKeyProgID: HKEY): HResult; reintroduce; stdcall;
    function AddPages(lpfnAddPage: TFNAddPropSheetPage; lParam: LParam): HResult; stdcall;
    function ReplacePage(uPageID: TEXPPS; lpfnReplaceWith: TFNAddPropSheetPage; lParam: LParam): HResult; stdcall;
  public
    FileNames: TFileNameArray;
  end;

  TDoSiSheetFactory = class(TAutoObjectFactory)
  public
    procedure UpdateRegistry(Register: Boolean); override;
  end;

  TSheetContentCallback = function(FileNames: TFileNameArray; out Content: IDoSiSheetContent): Boolean;
  
const
  nFalse: NativeBool = 0;
  nTrue:  NativeBool = 1;

  DialogTemplate: record
    Template: DLGTEMPLATE;
    MenuResource: SHORT;
    WindowClass: SHORT;
    Title: SHORT;
  end =(
    Template: (
      style: DS_CENTER or DS_CONTROL or WS_VISIBLE or WS_CHILD;
      dwExtendedStyle: WS_EX_LEFT;
      cdit: 0;
      x: 0;
      y: 0;
      cx: 200;
      cy: 200
    );
    MenuResource: 0;
    WindowClass: 0;
    Title: 0
  );
  
procedure AddSheetHandler(contentCallback: TSheetContentCallback);
procedure RemoveSheetHandler(contentCallback: TSheetContentCallback);

implementation

uses
  ComServ, ShellAPI, Messages, Registry;
 
var
  _contentCallback: TSheetContentCallback;
  
procedure AddSheetHandler(contentCallback: TSheetContentCallback);
begin
  _contentCallback := contentCallback;
end;

procedure RemoveSheetHandler(contentCallback: TSheetContentCallback);
begin
  if (@_contentCallback = @contentCallback) then
    _contentCallback := nil;
end;

function TDoSiSheet.CreateSheetContent: IDoSiSheetContent;
begin
  Result := nil;
  if ((@_contentCallback <> nil) and (not _contentCallback(FileNames, Result))) then
    Result := nil;
end;

function TDoSiSheet.Initialize(pidlFolder: PItemIDList; lpdobj: IDataObject; hKeyProgID: HKEY): HResult;
var
  i: Integer;
  StgMedium: TStgMedium;
  FormatEtc: TFormatEtc;
  Buffer: array[0..MAX_PATH] of Char;
begin
  Result := E_INVALIDARG;
  SetLength(FileNames, 0);

  if (lpdobj = nil) then
    Exit;

  with FormatEtc do
  begin
    cfFormat := CF_HDROP;
    ptd      := nil;
    dwAspect := DVASPECT_CONTENT;
    lindex   := -1;
    tymed    := TYMED_HGLOBAL;
  end;

  Result := lpdobj.GetData(FormatEtc, StgMedium);
  if Failed(Result) then
    Exit;

  for i := 0 to DragQueryFile(StgMedium.hGlobal, $FFFFFFFF, nil, 0) - 1 do
  begin
    DragQueryFile(StgMedium.hGlobal, i, Buffer, SizeOf(Buffer));

    SetLength(FileNames, i + 1);
    FileNames[i] := StrPas(Buffer);
  end;

  ReleaseStgMedium(StgMedium);
  Result := NOERROR;
end;

function OnInitDialog(hDlg: HWnd; lParam: LParam): NativeBool;
var
  Sheet: IDoSiSheetContent;
begin
  Sheet := IDoSiSheetContent(lParam);
  SetWindowLong(hDlg, GWL_USERDATA, NativeInt(Sheet));
  Result := Sheet.InitDialog(hDlg);
end;

procedure OnResize(hDlg: HWnd; lParam: LParam);
var
  Sheet: IDoSiSheetContent;
begin
  Sheet := IDoSiSheetContent(GetWindowLong(hDlg, GWL_USERDATA));
  Sheet.Resize(Integer(lParam) and $FFFF, Integer(lParam) div $10000);
end;

function OnApply(hDlg: HWnd; lParam: LParam): NativeBool;
var
  Sheet: IDoSiSheetContent;
begin
  Sheet := IDoSiSheetContent(GetWindowLong(hDlg, GWL_USERDATA));
  Result := Sheet.Apply(lParam <> nFalse);
end;

function OnReset(hDlg: HWnd; lParam: LParam): NativeBool;
var
  Sheet: IDoSiSheetContent;
begin
  Sheet := IDoSiSheetContent(GetWindowLong(hDlg, GWL_USERDATA));
  Result := Sheet.Reset();
end;

function OnCancel(hDlg: HWnd; lParam: LParam): NativeBool;
var
  Sheet: IDoSiSheetContent;
begin
  Sheet := IDoSiSheetContent(GetWindowLong(hDlg, GWL_USERDATA));
  Result := Sheet.Cancel();
end;

function DlgProc(hDlg: HWnd; uMessage: UInt; wParam: WParam; lParam: LParam): NativeBool; stdcall;
type
  TSHNotify = packed record
    hdr   : Windows.NMHdr;
    lParam: Windows.LParam;
  end;
  PSHNotify = ^TSHNotify;
begin
  Result := nFalse;

  case uMessage of
    WM_INITDIALOG:
      Result := OnInitDialog(hDlg, PPropSheetPage(lParam)^.lParam);

    WM_SIZE:
      OnResize(hDlg, lParam);

    WM_NOTIFY:
      begin
        Result := nTrue;
        case PNMHdr(lParam).code of
          PSN_RESET:
            Result := OnReset(hDlg, PSHNotify(lParam)^.lParam);

          PSN_APPLY:
            Result := OnApply(hDlg, PSHNotify(lParam)^.lParam);

          PSN_QUERYCANCEL:
            Result := OnCancel(hDlg, PSHNotify(lParam)^.lParam);
        end;

        if (Result <> nFalse) then
          SetWindowLong(hDlg, DWL_MSGRESULT, PSNRET_NOERROR);
      end;
  end;
end;

function CallbackProc(Wnd: HWnd; Msg: Integer; PPSP: PPropSheetPageW): Cardinal; stdcall;
begin
  Result := 0;

  case Msg of
    PSPCB_CREATE:
      Result := 1;

    //PSPCB_ADDREF:
    //  IDoSiSheetContent(PPSP.lParam)._AddRef();

    PSPCB_RELEASE:
      IDoSiSheetContent(PPSP.lParam)._Release();
  end;
end;

function TDoSiSheet.AddPages(lpfnAddPage: TFNAddPropSheetPage; lParam: LParam): HResult;
var
  Content: IDoSiSheetContent;
  PropSheet: TPropSheetPage;
  PropPage: Pointer;
  Title: string;
begin
  Result := E_FAIL;
  Content := CreateSheetContent();

  if (Content = nil) then
    Exit;

  Title := Content.GetTitle();

  FillChar(PropSheet, SizeOf(TPropSheetPage), 0);
  with PropSheet do
  begin
    dwSize      := SizeOf(TPropSheetPage);
    dwFlags     := PSP_DEFAULT or PSP_USETITLE or PSP_USEREFPARENT or PSP_USECALLBACK or PSP_DLGINDIRECT;
    hInstance   := SysInit.hInstance;
    pszTitle    := PChar(Title);
    pResource   := @DialogTemplate;
    pfnDlgProc  := @DlgProc;
    pfnCallback := @CallbackProc;
    pcRefParent := @ComServer.ObjectCount;
    lParam      := Windows.LPARAM(Content);
  end;

  PropPage := CreatePropertySheetPage(PropSheet);
  if PropPage <> nil then
  begin
    if lpfnAddPage(PropPage, lParam) then
    begin
      Content._AddRef();
      Result := NOERROR;
    end
    else
      DestroyPropertySheetPage(PropPage);
  end;
end;

function TDoSiSheet.ReplacePage(uPageID: TEXPPS; lpfnReplaceWith: TFNAddPropSheetPage; lParam: LParam): HResult;
begin
  Result := E_NOTIMPL;
end;

procedure TDoSiSheetFactory.UpdateRegistry(Register: Boolean);

  procedure Approve(const Add: Boolean; const ID: string);
  const
    ApproveShellExtension = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved';
  var
    Reg: TRegistry;
  begin
    if (Win32Platform <> VER_PLATFORM_WIN32_NT) then
      Exit;

    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;

      if (not Reg.OpenKey(ApproveShellExtension, True)) then
        Exit;

      if Add then
        Reg.WriteString(ID, Description)
      else
        Reg.DeleteValue(ID);
    finally
      Reg.Free;
    end;
  end;

const
  RegisterShellExtensionSuffix: string = '\shellex\PropertySheetHandlers\';
  RegisterShellExtensionKey: array[0..5] of string = (
    '*',
    'Directory',
    'Drive',
    'Folder',
    'LibraryLocation',
    'LibraryFolder'
  );

var
  i: Integer;
  GUID, RegisterPath: string;
begin
  inherited;

  GUID := GUIDToString(ClassID);
  Approve(Register, GUID);

  for i := Low(RegisterShellExtensionKey) to High(RegisterShellExtensionKey) do
  begin
    RegisterPath := RegisterShellExtensionKey[i] + RegisterShellExtensionSuffix + ClassName;
    if Register then
      CreateRegKey(RegisterPath, '', GUID, HKEY_CLASSES_ROOT)
    else
      DeleteRegKey(RegisterPath, HKEY_CLASSES_ROOT);
  end;
end;

initialization
  TDoSiSheetFactory.Create(ComServer, TDoSiSheet, Class_DoSiSheet, ciMultiInstance, tmApartment);
end.
