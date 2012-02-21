unit palitsa_scanner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TBaseDirScanner = class;

  TDirScannerEnterLeaveEvent = procedure(o : TBaseDirScanner; path : string) of object;
  TDirScannerFoundEvent = procedure(o : TBaseDirScanner; path : string; var f : TSearchRec) of object;

  TBaseDirScanner = class(TObject)
  private
    FOnEnterDirectory : TDirScannerEnterLeaveEvent;
    FOnLeaveDirectory : TDirScannerEnterLeaveEvent;
    FOnFoundEntry : TDirScannerFoundEvent;
  public
    property OnEnterDirectory : TDirScannerEnterLeaveEvent read FOnEnterDirectory write FOnEnterDirectory;
    property OnLeaveDirectory : TDirScannerEnterLeaveEvent read FOnLeaveDirectory write FOnLeaveDirectory;
    property OnFoundEntry : TDirScannerFoundEvent read FOnFoundEntry write FOnFoundEntry;


    procedure SearchFrom(path : string);virtual;abstract;

  end;


  /// factory function
  function CreateBaseDirScanner : TBaseDirScanner;

implementation

// 1) TSearchRec is always single. Scan the directory first and add directory names to a list.
// Then iterate over the list and search for descendant directory's contents.
// 2) Use many TSearchRec and employ recursive calls.

type

  { TImplDirScanner }

  TImplDirScanner = class(TBaseDirScanner)
    public
      procedure SearchFrom(path : string);override;

  end;


function CreateBaseDirScanner : TBaseDirScanner;
begin
  result := TImplDirScanner.Create;
end;

{ TImplDirScanner }

procedure TImplDirScanner.SearchFrom(path: string);
var
  rec : TSearchRec;
  newPath : string;

begin
  //inherited SearchFrom(path);
  newPath := IncludeTrailingPathDelimiter(path) + '*';
  //writeln(newPath);
  if FindFirst(newPath, faAnyFile, rec) = 0 then
  repeat
    if (rec.Name <> '') and (rec.Name <> '.') and (rec.Name <> '..') then
    begin
      if Assigned(OnFoundEntry) then
         OnFoundEntry(Self, path, rec);

      if (rec.Attr and faDirectory) <> 0 then

      begin
        newPath := IncludeTrailingPathDelimiter(path) + rec.Name;

        if Assigned(OnEnterDirectory) then
        begin
          OnEnterDirectory(Self, newPath);
        end;

        // recurse
        SearchFrom(newPath);

        if Assigned(OnLeaveDirectory) then
        begin
          OnLeaveDirectory(Self, newPath);
        end;
      end;
    end;
  until FindNext(rec) <> 0;

  FindClose(rec);
end;

end.

