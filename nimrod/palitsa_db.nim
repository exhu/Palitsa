# db access
import db_sqlite
import times
# ----
import sqlutils

type
    TEntityId* = distinct int64

const
    PALITSA_SCHEMA_FILE* = "db_schema1_sqlite.sql"
    PALITSA_SCHEMA_VERSION_INT* = 103
    NULL_ID* : TEntityId = TEntityId(0)
    ## we treat zero ID as SQL NULL. 

type
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



proc beginTransaction*(o: var TOpenDb)
proc endTransaction*(o: var TOpenDb, rollback: bool = false)

template InTransaction*(o: var TOpenDb, stmts: stmt) =
    o.beginTransaction
    try:
      stmts
      o.endTransaction
    except:
      o.endTransaction(true)
      raise




proc openDb*(o: var TOpenDb, fn: string, recreate: bool = false) =    
    o.conn = db_sqlite.open(fn, "", "", "")
    if recreate:
        let script = parseSqlFile(PALITSA_SCHEMA_FILE)
        for i in script:
            #echo "executing '" & i & "'..."
            inTransaction(o):
                db_sqlite.exec o.conn, TSqlQuery(i)
            
    
    
proc closeDb*(o: var TOpenDb) =    
    o.conn.close()

proc beginTransaction*(o: var TOpenDb) =    
    o.conn.exec sql"begin transaction;"
    o.inTransaction = true

proc endTransaction*(o: var TOpenDb, rollback: bool = false) =
    if not rollbacK:
        o.conn.exec sql"commit;"
    else:
        o.conn.exec sql"rollback;"
        
    o.inTransaction = false


proc genIdFor*(o: var TOpenDb, t: TPalTable): TEntityId =
  # TODO generate id via id_seq table

proc createMedia*(o: var TOpenDb, name, path: string, scanTime: TTime): 
    tuple[mediaId, rootId: TEntityId] =
  # TODO create media_desc, and root node

proc createEntry*(o: var TOpenDb, name, path: string, fileSize: int64, 
    mTime: TTime, isDir: bool, parent: TEntityId): TEntityId =
    # TODO
    
    

# ------------
when isMainModule:
    var a: TOpenDb
    
    a.openDb("ttt.db", recreate = true)
    a.closeDb()
  

