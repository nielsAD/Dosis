{
  Author: Niels A.D.
  Project: DoSiS (https://github.com/nielsAD/Dosis)
  License: GNU Lesser GPL (http://www.gnu.org/licenses/lgpl.html)

  Library entry
}
library DoSiS;

uses
  ComServ,
  ComObj,
  ActiveX,
  Forms,
  DoSiS_TLB in 'DoSiS_TLB.pas',
  DoSiSheet in 'DoSiSheet.pas' {DoSiSheet: CoClass},
  DoSiSheetDesign in 'DoSiSheetDesign.pas' {DoSiSheetContent: TFrame},
  CustomProtocol in 'CustomProtocol.pas',
  DoSiSheetFileSize in 'DoSiSheetFileSize.pas',
  DirectorySizeTree in 'DirectorySizeTree.pas',
  DocHostUIHandler in 'Lib\DocHostUIHandler.pas',
  WBNulContainer in 'Lib\WBNulContainer.pas';

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer,
  DllInstall;

{$R *.TLB}
{$R *.RES}
{$R 'TreeMap.res' 'TreeMap.rc'}

begin
  CoInitFlags := COINIT_APARTMENTTHREADED;
  Application.Initialize();
end.
