{
  Author: Niels A.D.
  Project: DoSiS (https://github.com/nielsAD/Dosis)
  License: GNU Lesser GPL (http://www.gnu.org/licenses/lgpl.html)

  Recursuve directory tree iterator
}
unit DirectorySizeTree;

interface

uses
  SysUtils;

type
  TDirectorySizeTree = class;
  TDirectorySizeTreeArray = array of TDirectorySizeTree;

  TFileWithSize = record
    Name: TFileName;
    Size: Int64;
  end;
  TFileWithSizeArray = array of TFileWithSize;

  TDirectorySizeTree = class
  protected
    FReady: Boolean;

    FPath: TFileName;
    FSuffix: string;
    FID: string;

    FFileCount: Integer;
    FTotalFileSize: Int64;
    FTotalDirSize: Int64;
    FFiles: TFileWithSizeArray;
    FSubDirectories: TDirectorySizeTreeArray;

    procedure IterateDirectory;
    function GetShortPath: TFileName;
    function GetTotalFileSize: Int64;
    function GetTotalDirSize: Int64;

    function GetFiles: TFileWithSizeArray;
    function GetFile(Index: string): TFileWithSize; overload;
    function GetFile(Index: string; Start: Integer): TFileWithSize; overload;

    function GetSubDirectories: TDirectorySizeTreeArray;
    function GetSubDirectory(Index: string): TDirectorySizeTree; overload;
    function GetSubDirectory(Index: string; Start: Integer): TDirectorySizeTree; overload;
  public
    constructor Create(const APath: TFileName; const AID: string); overload;
    constructor Create(const APathList: array of TFileName); overload;
    destructor Destroy; override;

    procedure Reset;
    function ToJSON(Depth: Integer = -1; MaxChildren: Integer = -1): string;

    property Path: TFileName read FPath;
    property ShortPath: TFileName read GetShortPath;
    property ID: string read FID;
    property FileCount: Integer read FFileCount;

    property TotalFileSize: Int64 read GetTotalFileSize;
    property TotalDirSize: Int64 read GetTotalDirSize;

    property Files: TFileWithSizeArray read GetFiles;
    property FileIndex[Index: string]: TFileWithSize read GetFile;

    property SubDirectories: TDirectorySizeTreeArray read GetSubDirectories;
    property SubDirectoryIndex[Index: string]: TDirectorySizeTree read GetSubDirectory;
  end;

implementation

uses
  Windows, Classes, Forms, Math;

function PackIndex(i: Integer): string;

  function Pack(x: Integer): string;
  begin
    if (x < 10) then
      Result := Char(Ord('0') + x)
    else if (x < 36) then
      Result := Char(Ord('A') + x - 10)
    else
      Result := Char(Ord('a') + x - 36);
  end;

begin
  if (i < 0) then
    Result := '_'
  else if (i < 62) then
    Result := Pack(i)
  else
  begin
    Result := '.';
    repeat
      Result := Pack(i mod 62) + Result;
      i := i div 62;
    until (i = 0);
    Result := '-' + Result;
  end;
end;

function UnpackIndex(const Index: string; var Start: Integer): Integer;

  function Unpack(x: Char): Integer;
  begin
    if (x >= '0') and (x <= '9') then
      Result := Ord(x) - Ord('0')
    else if (x >= 'A') and (x <= 'Z') then
      Result := Ord(x) - Ord('A') + 10
    else
      Result := Ord(x) - Ord('a') + 36;
  end;

var
  c: Char;
begin
  if (Start < 1) or (Start > Length(Index)) then
    Result := -1
  else
  begin
    c := Index[Start];
    if (c = '_') or (c = ':') or (c = '.') then
      Result := -1
    else if (c <> '-') then
      Result := Unpack(c)
    else
    begin
      Result := 0;
      repeat
        Inc(Start);
        if (Start > Length(Index)) then
          Break;
        c := Index[Start];
        if (c = '.') then
          Break;
        Result := Result * 62 + Unpack(c);
      until False;
    end;
    Inc(Start);
  end;
end;

procedure TDirectorySizeTree.IterateDirectory;
var
  SearchRec: TSearchRec;
  DirCount, DirLen: Integer;
begin
  if FReady then
    Exit;

  Reset();
  DirCount := 0;
  DirLen   := 0;

  if (FPath <> '') and (SysUtils.FindFirst(FPath + '*', faAnyFile - faSymLink, SearchRec) = 0) then
  try
    repeat
      if (SearchRec.Attr and FILE_ATTRIBUTE_REPARSE_POINT) <> 0 then
        Continue;
      if (SearchRec.Attr and faDirectory) = 0 then
      begin
        Inc(FFileCount);
        Inc(FTotalFileSize, SearchRec.Size);
      end
      else if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        Inc(DirCount);
        if (DirCount >= DirLen) then
        begin
          DirLen := Ceil(DirCount * 1.5);
          SetLength(FSubDirectories, DirLen);
        end;
        FSubDirectories[DirCount - 1] := TDirectorySizeTree.Create(FPath + SearchRec.Name, FID + PackIndex(DirCount - 1));
      end;
    until (SysUtils.FindNext(SearchRec) <> 0);
  finally
    SysUtils.FindClose(SearchRec);
    Application.ProcessMessages();
  end;

  DirLen := DirCount;
  SetLength(FSubDirectories, DirCount);

  FReady := True;
end;

function TDirectorySizeTree.GetShortPath: TFileName;
var
  Short: TFileName;
begin
  Short  := ExcludeTrailingPathDelimiter(FPath);
  Result := ExtractFileName(Short);

  if (Result = '') then
    Result := Short;
end;

function TDirectorySizeTree.GetTotalFileSize: Int64;
begin
  IterateDirectory();
  Result := FTotalFileSize;
end;

function TDirectorySizeTree.GetTotalDirSize: Int64;
var
  i: Integer;
begin
  IterateDirectory();

  if (FTotalDirSize = -1) then
  begin
    FTotalDirSize := FTotalFileSize;
    for i := Low(FSubDirectories) to High(FSubDirectories) do
      Inc(FTotalDirSize, FSubDirectories[i].TotalDirSize);
  end;

  Result := FTotalDirSize;
end;

function TDirectorySizeTree.GetFiles: TFileWithSizeArray;
var
  SearchRec: TSearchRec;
  i: Integer;
begin
  IterateDirectory();

  if (FFiles = nil) and (FFileCount > 0) then
  begin
    i := 0;
    SetLength(FFiles, FFileCount);

    if SysUtils.FindFirst(FPath + '*', faAnyFile - faDirectory, SearchRec) = 0 then
      try
        repeat
          FFiles[i].Name := SearchRec.Name;
          FFiles[i].Size := SearchRec.Size;
          Inc(i);
        until (SysUtils.FindNext(SearchRec) <> 0) or (i >= FFileCount);
      finally
        SysUtils.FindClose(SearchRec);
      end;
  end;

  Result := FFiles;
end;

function TDirectorySizeTree.GetFile(Index: string; Start: Integer): TFileWithSize;
const
  NullFileWithSize: TFileWithSize = (Name: ''; Size: -1);
var
  i: Integer;
  d: TDirectorySizeTree;
begin
  if (Index[Start] = ':') then
  begin
    GetFiles();

    Inc(Start);
    i := UnpackIndex(Index, Start);
    Assert(Start > Length(Index));

    if (i >= 0) and (i < Length(FFiles)) then
      Exit(FFiles[i]);
  end
  else
  begin
    d := GetSubDirectory(Index, Start);
    if (d <> nil) then
      Exit(d.GetFile(Index, Start));
  end;

  Result := NullFileWithSize;
end;

function TDirectorySizeTree.GetFile(Index: string): TFileWithSize;
begin
  Result := GetFile(Index, 1);
end;

function TDirectorySizeTree.GetSubDirectories: TDirectorySizeTreeArray;
begin
  IterateDirectory();
  Result:= FSubDirectories;
end;

function TDirectorySizeTree.GetSubDirectory(Index: string; Start: Integer): TDirectorySizeTree;
var
  i: Integer;
begin
  GetSubDirectories();

  i := UnpackIndex(Index, Start);
  if (i >= 0) and (i < Length(FSubDirectories)) then
    Result := FSubDirectories[i].GetSubDirectory(Index, Start)
  else if (Start > Length(Index)) then
    Result := Self
  else
    Result := nil;
end;

function TDirectorySizeTree.GetSubDirectory(Index: string): TDirectorySizeTree;
begin
  Result := GetSubDirectory(Index, 1);
end;

constructor TDirectorySizeTree.Create(const APath: TFileName; const AID: string);
begin
  inherited Create();
  Reset();

  FPath   := IncludeTrailingPathDelimiter(APath);
  FSuffix := '';
  FID     := AID;
  FReady  := False;
end;

constructor TDirectorySizeTree.Create(const APathList: array of TFileName);

  function GetFileSize(const FileName: TFileName): Int64;
  var
    SearchRec: TSearchRec;
  begin
    if (SysUtils.FindFirst(FileName, faAnyfile, SearchRec) = 0) then
    try
      Result := SearchRec.Size;
    finally
      SysUtils.FindClose(SearchRec);
    end
    else
      Result := 0;
  end;

var
  i, DirCount: Integer;
begin
  if (Length(APathList) = 1) and DirectoryExists(APathList[0]) then
    Create(APathList[0], '')
  else if (Length(APathList) < 1) then
    Create('', '')
  else
  begin
    inherited Create();
    Reset();

    FPath   := ExtractFileDir(ExcludeTrailingPathDelimiter(APathList[0]));
    FSuffix := ' (selection)';
    FID     := '';
    FReady  := True;

    DirCount := 0;
    for i := Low(APathList) to High(APathList) do
      if DirectoryExists(APathList[i]) then
      begin
        Inc(DirCount);
        SetLength(FSubDirectories, DirCount);
        FSubDirectories[DirCount - 1] := TDirectorySizeTree.Create(APathList[i], PackIndex(DirCount - 1));
      end
      else
      begin
        Inc(FFileCount);
        SetLength(FFiles, FFileCount);
        with FFiles[FFileCount - 1] do
        begin
          Name := ExtractFileName(APathList[i]);
          Size := GetFileSize(APathList[i]);
          Inc(FTotalFileSize, Size);
        end;
      end;
  end;
end;

destructor TDirectorySizeTree.Destroy;
begin
  Reset();
  inherited Destroy();
end;

procedure TDirectorySizeTree.Reset;
var
  i: Integer;
begin
  FFileCount     := 0;
  FTotalFileSize := 0;
  FTotalDirSize  := -1;

  for i := Low(FSubDirectories) to High(FSubDirectories) do
    FSubDirectories[i].Free();

  FFiles := nil;
  FSubDirectories := nil;
end;

function TDirectorySizeTree.ToJSON(Depth: Integer = -1; MaxChildren: Integer = -1): string;
const
  StrFormatFile = '{"id":"F%s","name":"%s","data":{"$area":%d,"isFile":1}}';
  StrFormatDir  = '{"id":"D%s","name":"%s","data":{"$area":%d},"children":[%s]}';
type
  TGetSize = reference to function(Index: Pointer): Int64;

  function Escape(const s: string): string;
  begin
    Result := StringReplace(StringReplace(s, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]);
  end;

  function SumSize(List: TList; GetSize: TGetSize; StartIdx, EndIdx: Integer): Int64;
  var
    i: Integer;
  begin
    Result := 0;
    for i := Max(StartIdx, 0) to Min(EndIdx, List.Count - 1) do
      Inc(Result, GetSize(List[i]));
  end;

var
  i, Index, Count: Integer;
  ChildIndices: TList;
  Children: string;
  GetSize: TGetSize;
begin
  Children := '';
  ChildIndices := nil;

  if (Depth <> 0) then
  try
    GetFiles();
    GetTotalDirSize();
    Assert(FFileCount = Length(FFiles));

    ChildIndices := TList.Create();
    ChildIndices.Capacity := FFileCount + Length(FSubDirectories);

    for i := Low(FFiles) to High(FFiles) do
      ChildIndices.Add(Pointer(i));
    for i := Low(FSubDirectories) to High(FSubDirectories) do
      ChildIndices.Add(Pointer(i + FFileCount));

    if (MaxChildren > 0) then
    begin
      GetSize :=
        function(Index: Pointer): Int64
        var
          Idx: NativeInt absolute Index;
        begin
          if (Idx < FFileCount) then
            Result := FFiles[Idx].Size
          else
            Result := FSubDirectories[Idx - FFileCount].TotalFileSize;
        end;

      ChildIndices.SortList(
        function(Left, Right: Pointer): Integer
        begin
          Result := Sign(GetSize(Right) - GetSize(Left));
        end
      );
    end;

    if (MaxChildren > 0) then
      Count := MaxChildren - 1
    else
      Count := MaxInt;

    if (ChildIndices.Count - Count = 1) then
      Inc(Count);

    for i := 0 to Min(ChildIndices.Count, Count) - 1 do
    begin
      if (Children <> '') then
        Children := Children + ',';

      Index := NativeInt(ChildIndices[i]);
      if (Index < FFileCount) then
        Children := Children + Format(StrFormatFile, [FID + ':' + PackIndex(Index), Escape(FFiles[Index].Name), FFiles[Index].Size + 1])
      else
        Children := Children + FSubDirectories[Index - FFileCount].ToJSON(Depth - 1, MaxChildren)
    end;

    if (Count < ChildIndices.Count) then
      Children := Children + ',' + Format(StrFormatFile, [FID + ':*', IntToStr(ChildIndices.Count - Count) + ' files*', SumSize(ChildIndices, GetSize, Count, ChildIndices.Count - 1)]);
  finally
    if (ChildIndices <> nil) then
      ChildIndices.Free();
    Application.ProcessMessages();
  end;

  Result := Format(StrFormatDir, [FID, Escape(ShortPath) + FSuffix, TotalDirSize + 1, Children]);
end;

end.
