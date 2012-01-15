unit palitsa_base;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 

const
  PALITSA_DB_VER = 102;
  PALITSA_DB_VER_STR = '1.2';

  NULL_ID = 0; //< like NULL in SQL for int64 fields.

type

  { TEntity }

  TEntity = class
    id: int64;


  end;

  { TMediaDescEntity }

  TMediaDescEntity = class(TEntity)
    name : string;
    original_path : string;
    scan_time : longint;

    /// dir_entry_desc id
    root_id : int64;
  end;


  { TDirEntryDescEntity }

  TDirEntryDescEntity = class(TEntity)
    parent_id : int64; //< null if root
    dir_path : string;
    name : string;
    file_size : int64;
    mtime : longint;
    desc_id : int64; //< description entity id (optional)

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

  TBaseMediaDescDAO = class
    function get(id: int64): TMediaDescEntity; virtual; abstract;
    function insert(e: TMediaDescEntity) : boolean; virtual; abstract;

    function update_name(e : TMediaDescEntity) : boolean; virtual; abstract;

    function remove(e : TMediaDescEntity) : boolean; virtual; abstract;
  end;

implementation



end.

