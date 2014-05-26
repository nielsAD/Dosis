//This code is based on github.com/jasonpenny/twebbrowser.utilities
unit CustomProtocol;

interface

uses
  Windows, Classes, ComObj, UrlMon, DoSiS_TLB, StdVcl;

type
  TByteArray = array of byte;

  TCustomProtocol = class(TComObject, IInternetProtocol, ICustomProtocol)
  protected
    FProtocolSink: IInternetProtocolSink;
    FData : TMemoryStream;

    function GetPostData(OIBindInfo: IInternetBindInfo; out mimeType: string; out postData: TByteArray): Boolean;
  public
    procedure Initialize; override;
    destructor Destroy; override;

    function Start(szUrl: LPCWSTR; OIProtSink: IInternetProtocolSink; OIBindInfo: IInternetBindInfo; grfPI, dwReserved: DWORD): HResult; stdcall;
    function Continue(const ProtocolData: TProtocolData): HResult; stdcall;
    function Abort(hrReason: HResult; dwOptions: DWORD): HResult; stdcall;
    function Terminate(dwOptions: DWORD) : HResult; stdcall;
    function Suspend: HResult; stdcall;
    function Resume: HResult; stdcall;

    function Read(pv: Pointer; cb: ULONG; out cbRead: ULONG): HResult; stdcall;
    function Seek(dlibMove: LARGE_INTEGER; dwOrigin: DWORD; out libNewPosition: ULARGE_INTEGER): HResult; stdcall;
    function LockRequest(dwOptions: DWORD): HResult; stdcall;
    function UnlockRequest: HResult; stdcall;
 end;

  TProtocolCallback = function(
    aURL: string;
    var aMIMEType: string;
    const aPostMIMEType: string;
    const aPostData: TByteArray;
    aMemoryStream: TCustomMemoryStream
  ): Boolean of object;

const
  Class_StdURLProtocol: TGUID = '{79eac9e1-baf9-11ce-8c82-00aa004ba90b}';
  Class_HttpProtocol:   TGUID = '{79eac9e2-baf9-11ce-8c82-00aa004ba90b}';
  Class_FtpProtocol:    TGUID = '{79eac9e3-baf9-11ce-8c82-00aa004ba90b}';
  Class_GopherProtocol: TGUID = '{79eac9e4-baf9-11ce-8c82-00aa004ba90b}';
  Class_HttpsProtocol:  TGUID = '{79eac9e5-baf9-11ce-8c82-00aa004ba90b}';
  Class_MKProtocol:     TGUID = '{79eac9e6-baf9-11ce-8c82-00aa004ba90b}';
  Class_FileProtocol:   TGUID = '{79eac9e7-baf9-11ce-8c82-00aa004ba90b}';

procedure AddProtocolHandler(const aProtocolName: string; aProtocolCallback: TProtocolCallback; aProtocolType: TGUID); overload;
procedure AddProtocolHandler(const aProtocolName: string; aProtocolCallback: TProtocolCallback); overload;
procedure EndProtocolHandler;

implementation

uses
  ComServ, ActiveX;

var
  Factory: IClassFactory;
  InternetSession: IInternetSession;
  InternetProtocol: IInternetProtocol;

  _protocol: string = '';
  _protocolCallback: TProtocolCallback;

procedure AddProtocolHandler(const aProtocolName: string; aProtocolCallback: TProtocolCallback; aProtocolType: TGUID);
begin
  if (_protocol <> '') then
    EndProtocolHandler();

  _protocol := aProtocolName;
  _protocolCallback := aProtocolCallback;

  CoGetClassObject(Class_CustomProtocol, CLSCTX_SERVER, nil, IClassFactory, Factory);
  CoInternetGetSession(0, InternetSession, 0);
  InternetSession.RegisterNameSpace(Factory, Class_CustomProtocol, PChar(_protocol), 0, nil, 0);

  CoCreateInstance(aProtocolType, nil, CLSCTX_INPROC_SERVER, IUnknown, InternetProtocol);
end;

procedure AddProtocolHandler(const aProtocolName: string; aProtocolCallback: TProtocolCallback);
begin
  AddProtocolHandler(aProtocolName, aProtocolCallback, Class_HttpProtocol);
end;

procedure EndProtocolHandler;
begin
  if Assigned(InternetSession) then
    InternetSession.UnregisterNameSpace(Factory, PChar(_protocol));

  InternetProtocol := nil;
  InternetSession := nil;
  Factory := nil;

  _protocolCallback := nil;
  _protocol := '';
end;

function DoProtocolCallback(aURL: string; var aMIMEType: string; const aPostMIMEType: string; const aPostData: TByteArray; aMemoryStream: TCustomMemoryStream): Boolean;
begin
  if (@_protocolCallback = nil) then
    Result := False
  else
    Result := _protocolCallback(aURL, aMIMEType, aPostMIMEType, aPostData, aMemoryStream);
end;

{ TCustomProtocol }
function TCustomProtocol.GetPostData(OIBindInfo: IInternetBindInfo; out mimeType: string; out postData: TByteArray): Boolean;
var
  LBindInfo: TBindInfo;
  BINDF: DWORD;
  cPostData: UINT;
  pData: Pointer;
  pszMIMEType: POleStrArray;
  dwSize: ULONG;
begin
  FillChar(LBindInfo, SizeOf(LBindInfo), 0);
  LBindInfo.cbSize := SizeOf(LBindInfo);

  mimeType := '';
  postData := nil;
  pszMIMEType := nil;
  Result := True;

  OIBindInfo.GetBindInfo(BINDF, LBindInfo);
  if ((LBindInfo.dwBindVerb <> BINDVERB_POST) or (LBindInfo.stgmedData.tymed <> TYMED_HGLOBAL)) then
    Exit;

  cPostData := LBindInfo.cbstgmedData;
  if cPostData < 1 then
    Exit;

  pData := GlobalLock(LBindInfo.stgmedData.hGlobal);
  if pData = nil then
    Exit(False);

  try
    SetLength(postData, cPostData+1);
    CopyMemory(postData, pData, cPostData);
  finally
    GlobalUnlock(LBindInfo.stgmedData.hGlobal);
  end;

  if (OIBindInfo.GetBindString(BINDSTRING_POST_DATA_MIME, @pszMIMEType, 1, dwSize) <> S_OK) then
    mimeType := 'application/x-www-form-urlencoded'
  else if (pszMIMEType <> nil) then
  begin
    mimeType := PWideChar(pszMIMEType);
    CoTaskMemFree(pszMIMEType);
  end;
end;

procedure TCustomProtocol.Initialize;
begin
  inherited;
  FData := TMemoryStream.Create();
end;

destructor TCustomProtocol.Destroy;
begin
  FData.Free();
  FProtocolSink := nil;
  inherited;
end;

function TCustomProtocol.Start(szUrl: LPCWSTR; OIProtSink: IInternetProtocolSink; OIBindInfo: IInternetBindInfo; grfPI, dwReserved: DWORD): HResult;

  function ParseURL(const aURL: string): string;
  begin
    if (Pos(':', aURL) > 0) then
      Result := Copy(aURL, Pos(':', aURL)+1)
    else
      Result := '';
  end;

var
  URL, mimeType, postMimeType: string;
  postData: TByteArray;
begin
  FProtocolSink := OIProtSink;
  URL := ParseURL(szURL);
  if ((URL = '') or (not GetPostData(OIBindInfo, postMimeType, postData))) then
    Exit(INET_E_USE_DEFAULT_PROTOCOLHANDLER);

  FData.Clear;
  mimeType := 'text/html';

  if (not DoProtocolCallback(URL, mimeType, postMimeType, postData, FData)) then
    Exit(INET_E_USE_DEFAULT_PROTOCOLHANDLER);

  FProtocolSink.ReportProgress(BINDSTATUS_FINDINGRESOURCE,           '');
  FProtocolSink.ReportProgress(BINDSTATUS_CONNECTING,                '');
  FProtocolSink.ReportProgress(BINDSTATUS_SENDINGREQUEST,            '');
  FProtocolSink.ReportProgress(BINDSTATUS_VERIFIEDMIMETYPEAVAILABLE, PChar(mimeType));

  FData.Position := 0;
  FProtocolSink.ReportData(
    UrlMon.BSCF_FIRSTDATANOTIFICATION or UrlMon.BSCF_LASTDATANOTIFICATION or BSCF_DATAFULLYAVAILABLE,
    FData.Size,
    FData.Size
  );

  Result := S_OK;
end;

function TCustomProtocol.Continue(const ProtocolData: TProtocolData): HResult;
begin
  Result := E_FAIL;
end;

function TCustomProtocol.Abort(hrReason: HResult; dwOptions: DWORD): HResult;
begin
  if Assigned(FProtocolSink) then
    FProtocolSink.ReportResult(hrReason, 0, nil);
  Result := S_OK;
end;

function TCustomProtocol.Suspend: HResult;
begin
  Result := E_NOTIMPL;
end;

function TCustomProtocol.Resume: HResult;
begin
  Result := E_NOTIMPL;
end;

function TCustomProtocol.Terminate(dwOptions: DWORD): HResult;
begin
  FProtocolSink := nil;
  Result := S_OK;
end;

function TCustomProtocol.Read(pv: Pointer; cb: ULONG; out cbRead: ULONG): HResult;
begin
  Result := S_OK;

  cbRead := FData.Size - FData.Position;
  if (cb < cbRead) then
    cbRead := cb;

  if (FData.Position < FData.Size) then
    FData.ReadBuffer(pv^, cbRead);

  if (FData.Position >= FData.Size) then
  begin
    if Assigned(FProtocolSink) then
      FProtocolSink.ReportResult(S_OK, 0, nil);
    Result := S_FALSE;
  end;
end;

function TCustomProtocol.Seek(dlibMove: LARGE_INTEGER; dwOrigin: DWORD; out libNewPosition: ULARGE_INTEGER): HResult;
begin
  Result := E_NOTIMPL;
end;

function TCustomProtocol.LockRequest(dwOptions: DWORD): HResult;
begin
  Result := S_OK;
end;

function TCustomProtocol.UnlockRequest: HResult;
begin
  Result := S_OK;
end;

initialization
  TComObjectFactory.Create(ComServer, TCustomProtocol, Class_CustomProtocol, 'CustomProtocol', 'DoSiS', ciMultiInstance, tmApartment);
finalization
  EndProtocolHandler();
end.
