unit DoSiS_TLB;

// ************************************************************************ //
// WARNING
// -------
// The types declared in this file were generated from data read from a
// Type Library. If this type library is explicitly or indirectly (via
// another type library referring to this type library) re-imported, or the
// 'Refresh' command of the Type Library Editor activated while editing the
// Type Library, the contents of this file will be regenerated and all
// manual modifications will be lost.
// ************************************************************************ //

// $Rev: 41960 $
// File generated on 25-5-2014 10:00:13 from Type Library described below.

// ************************************************************************  //
// Type Lib: D:\Documenten\RAD Studio\Projects\DoSiS\Src\Sheet\DoSiS (1)
// LIBID: {317DAA20-FDEF-4A0D-93F3-30DC39F4359D}
// LCID: 0
// Helpfile:
// HelpString:
// DepndLst:
//   (1) v2.0 stdole, (C:\Windows\SysWOW64\stdole2.tlb)
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers.
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
{$ALIGN 4}

interface

uses Windows, ActiveX, Classes, Graphics, OleServer, StdVCL, Variants;


// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:
//   Type Libraries     : LIBID_xxxx
//   CoClasses          : CLASS_xxxx
//   DISPInterfaces     : DIID_xxxx
//   Non-DISP interfaces: IID_xxxx
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  DoSiSMajorVersion = 0;
  DoSiSMinorVersion = 1;

  LIBID_DoSiS: TGUID = '{317DAA20-FDEF-4A0D-93F3-30DC39F4359D}';

  IID_IDoSiSheet: TGUID = '{0D8886EB-4635-407E-BFB9-17596BA444B5}';
  CLASS_DoSiSheet: TGUID = '{03FC5DCC-CBED-4B8F-BFA2-7ADF1F1AD499}';
  IID_ICustomProtocol: TGUID = '{F5962CE1-E8EF-44B7-ACAB-5F1AA18038D2}';
  CLASS_CustomProtocol: TGUID = '{5CED005A-E514-4C8C-9D6B-D2FF690B8DE8}';
  IID_IInterop: TGUID = '{D05D6017-9B1C-419D-9D06-539A8EA3BE6A}';
  CLASS_Interop: TGUID = '{0BD873D5-EEE2-4E75-9A23-37651CA0F95A}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary
// *********************************************************************//
  IDoSiSheet = interface;
  IDoSiSheetDisp = dispinterface;
  ICustomProtocol = interface;
  ICustomProtocolDisp = dispinterface;
  IInterop = interface;
  IInteropDisp = dispinterface;

// *********************************************************************//
// Declaration of CoClasses defined in Type Library
// (NOTE: Here we map each CoClass to its Default Interface)
// *********************************************************************//
  DoSiSheet = IDoSiSheet;
  CustomProtocol = ICustomProtocol;
  Interop = IInterop;


// *********************************************************************//
// Interface: IDoSiSheet
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {0D8886EB-4635-407E-BFB9-17596BA444B5}
// *********************************************************************//
  IDoSiSheet = interface(IDispatch)
    ['{0D8886EB-4635-407E-BFB9-17596BA444B5}']
  end;

// *********************************************************************//
// DispIntf:  IDoSiSheetDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {0D8886EB-4635-407E-BFB9-17596BA444B5}
// *********************************************************************//
  IDoSiSheetDisp = dispinterface
    ['{0D8886EB-4635-407E-BFB9-17596BA444B5}']
  end;

// *********************************************************************//
// Interface: ICustomProtocol
// Flags:     (320) Dual OleAutomation
// GUID:      {F5962CE1-E8EF-44B7-ACAB-5F1AA18038D2}
// *********************************************************************//
  ICustomProtocol = interface(IUnknown)
    ['{F5962CE1-E8EF-44B7-ACAB-5F1AA18038D2}']
  end;

// *********************************************************************//
// DispIntf:  ICustomProtocolDisp
// Flags:     (320) Dual OleAutomation
// GUID:      {F5962CE1-E8EF-44B7-ACAB-5F1AA18038D2}
// *********************************************************************//
  ICustomProtocolDisp = dispinterface
    ['{F5962CE1-E8EF-44B7-ACAB-5F1AA18038D2}']
  end;

// *********************************************************************//
// Interface: IInterop
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {D05D6017-9B1C-419D-9D06-539A8EA3BE6A}
// *********************************************************************//
  IInterop = interface(IDispatch)
    ['{D05D6017-9B1C-419D-9D06-539A8EA3BE6A}']
    function Get_DoSiS: WideString; safecall;
    procedure log(const Str: WideString); safecall;
    function getDirectoryTree(const Index: WideString; Depth: Integer): WideString; safecall;
    procedure Set_maxChildren(Value: Integer); safecall;
    property DoSiS: WideString read Get_DoSiS;
    property maxChildren: Integer write Set_maxChildren;
  end;

// *********************************************************************//
// DispIntf:  IInteropDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {D05D6017-9B1C-419D-9D06-539A8EA3BE6A}
// *********************************************************************//
  IInteropDisp = dispinterface
    ['{D05D6017-9B1C-419D-9D06-539A8EA3BE6A}']
    property DoSiS: WideString readonly dispid 201;
    procedure log(const Str: WideString); dispid 202;
    function getDirectoryTree(const Index: WideString; Depth: Integer): WideString; dispid 203;
    property maxChildren: Integer writeonly dispid 204;
  end;

// *********************************************************************//
// The Class CoDoSiSheet provides a Create and CreateRemote method to
// create instances of the default interface IDoSiSheet exposed by
// the CoClass DoSiSheet. The functions are intended to be used by
// clients wishing to automate the CoClass objects exposed by the
// server of this typelibrary.
// *********************************************************************//
  CoDoSiSheet = class
    class function Create: IDoSiSheet;
    class function CreateRemote(const MachineName: string): IDoSiSheet;
  end;

// *********************************************************************//
// The Class CoCustomProtocol provides a Create and CreateRemote method to
// create instances of the default interface ICustomProtocol exposed by
// the CoClass CustomProtocol. The functions are intended to be used by
// clients wishing to automate the CoClass objects exposed by the
// server of this typelibrary.
// *********************************************************************//
  CoCustomProtocol = class
    class function Create: ICustomProtocol;
    class function CreateRemote(const MachineName: string): ICustomProtocol;
  end;

// *********************************************************************//
// The Class CoInterop provides a Create and CreateRemote method to
// create instances of the default interface IInterop exposed by
// the CoClass Interop. The functions are intended to be used by
// clients wishing to automate the CoClass objects exposed by the
// server of this typelibrary.
// *********************************************************************//
  CoInterop = class
    class function Create: IInterop;
    class function CreateRemote(const MachineName: string): IInterop;
  end;

implementation

uses ComObj;

class function CoDoSiSheet.Create: IDoSiSheet;
begin
  Result := CreateComObject(CLASS_DoSiSheet) as IDoSiSheet;
end;

class function CoDoSiSheet.CreateRemote(const MachineName: string): IDoSiSheet;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_DoSiSheet) as IDoSiSheet;
end;

class function CoCustomProtocol.Create: ICustomProtocol;
begin
  Result := CreateComObject(CLASS_CustomProtocol) as ICustomProtocol;
end;

class function CoCustomProtocol.CreateRemote(const MachineName: string): ICustomProtocol;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_CustomProtocol) as ICustomProtocol;
end;

class function CoInterop.Create: IInterop;
begin
  Result := CreateComObject(CLASS_Interop) as IInterop;
end;

class function CoInterop.CreateRemote(const MachineName: string): IInterop;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_Interop) as IInterop;
end;

end.

