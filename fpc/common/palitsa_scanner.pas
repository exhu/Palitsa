unit palitsa_scanner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TBaseDirScanner = class;

  TDirScannerEnterLeaveEvent = procedure(o : TBaseDirScanner; path, name : string) of object;
  TDirScannerFoundEvent = procedure(o : TBaseDirScanner; var f : TSearchRec) of object;

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
begin
  //inherited SearchFrom(path);
end;

end.

