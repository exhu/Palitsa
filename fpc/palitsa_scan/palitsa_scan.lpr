program palitsa_scan;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp, palitsa_base, palitsa_scanner
  { you can add units after this };

type

  { TScanDirApplication }

  TScanDirApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;

    ////
    procedure OnEnterDirectory(o : TBaseDirScanner; path : string);
    procedure OnFound(o : TBaseDirScanner; path : string; var f : TSearchRec);
  end;

{ TScanDirApplication }

procedure TScanDirApplication.DoRun;
var
  ErrorMsg: String;
  dirsc : TBaseDirScanner;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions('h','help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h','help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  { add your program here }


  dirsc := CreateBaseDirScanner;
  dirsc.OnEnterDirectory:= @OnEnterDirectory;
  dirsc.OnFoundEntry:= @OnFound;
  dirsc.SearchFrom(ParamStr(1));//'/home/yuryb/man');
  dirsc.Free;

  readln;
  // stop program loop
  Terminate;
end;

constructor TScanDirApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TScanDirApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TScanDirApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ',ExeName,' -h');
end;

procedure TScanDirApplication.OnEnterDirectory(o: TBaseDirScanner; path: string
  );
begin
  writeln('Entering dir ' + path);
end;

procedure TScanDirApplication.OnFound(o: TBaseDirScanner; path: string;
  var f: TSearchRec);
begin
  writeln('Found item ' + f.Name);
end;

var
  Application: TScanDirApplication;

{$R *.res}

begin
  Application:=TScanDirApplication.Create(nil);
  Application.Run;
  Application.Free;
end.

