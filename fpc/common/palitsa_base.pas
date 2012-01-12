unit palitsa_base;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 

const
  PALITSA_DB_VER = 102;
  PALITSA_DB_VER_STR = '1.2';

type
  PMediaDescEntity = ^TMediaDescEntity;
  TMediaDescEntity = record
    id : int64;

  end;



  TOpenStatus = (osOK, osWrongVersion, osError);

  TBaseDB = class
    function open(fn : string) : TOpenStatus; virtual; abstract;
    procedure close; virtual; abstract;

    /// generates id for new row to be put into the specified table
    function generate_id(table_name : string) : int64; virtual; abstract;

    function get_notes : string; virtual; abstract;
    procedure update_notes(n : string); virtual; abstract;
  end;

implementation

end.

