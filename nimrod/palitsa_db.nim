# db access
import db_sqlite
import times
# ----
import sqlutils

const
    PALITSA_SCHEMA_FILE = "db_schema1_sqlite.sql"
    PALITSA_SCHEMA_VERSION_INT = 103
    NULL_ID* = 0
    ## we treat zero ID as SQL NULL. 

type
    TEntityId* = distinct int64
    TOpenDb* = object
        conn: TDbConn
        inTransaction: bool
        
    TPalTable = enum
        ptMediaDesc = "media_desc",
        ptDirEntryDesc = "dir_entry_desc",
        ptTextDesc = "text_desc",
        ptTagDesc = "tag_desc",
        ptTagDirEntryAssoc = "tag_dir_entry_assoc"

    TDirEntryDesc = object
        id: TEntityId
        name, path: string
        fileSize: int64
        mTime: TTime
        isDir: bool
        parent: TEntityId
        descId: TEntityId


proc openDb*(o: var TOpenDb, fn: string, recreate: bool = false) =
    # TODO open it
    
    
proc closeDb*(o: var TOpenDb) =
    # TODO

proc beginTransaction*(o: var TOpenDb) =
    # TODO

proc endTransaction*(o: var TOpenDb, rollback: bool = false) =
    # TODO


template InTransaction*(o: var TOpenDb, stmts: stmt) =
    o.beginTransaction
    try:
      stmts
      o.endTransaction
    except:
      o.endTransaction(true)
      raise


proc genIdFor*(o: var TOpenDb, t: TPalTable): TEntityId =
  # TODO generate id via id_seq table

proc createMedia*(o: var TOpenDb, name, path: string, scanTime: TTime): 
    tuple[mediaId, rootId: TEntityId] =
  # TODO create media_desc, and root node

proc createEntry*(o: var TOpenDb, name, path: string, fileSize: int64, 
    mTime: TTime, isDir: bool, parent: TEntityId): TEntityId =
    # TODO
    
    

var a: TOpenDb
InTransaction(a):
  discard genIdFor(a, ptDirEntryDesc)
  

