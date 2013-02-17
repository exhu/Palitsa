# db access
import db_sqlite
import times
import logging
import os
import parseutils, strutils
# ----
import palitsa_sqlutils


 
const
    PALITSA_SCHEMA_FILE* = "db_schema1_sqlite.sql"
    PALITSA_SCHEMA_VERSION_INT* = 103    


type
        
    TPalTable* = enum
        ptMediaDesc = "media_desc",
        ptDirEntryDesc = "dir_entry_desc",
        ptTextDesc = "text_desc",
        ptTagDesc = "tag_desc",
        ptTagDirEntryAssoc = "tag_dir_entry_assoc"


    TDirEntryDesc* = object
        ## used for inserting new entries and querrying
        id*: TEntityId
        name*, path*: string
        fileSize*: int64
        mTime*: TTime
        isDir*: bool
        parentId*: TEntityId
        descId*: TEntityId

    TMediaDesc* = object
        ## used for inserting new entries and querrying
        id*: TEntityId
        name*: string
        originalPath*: string
        scanTime*: TTime
        rootId*: TEntityId



proc openDb*(o: var TOpenDb, fn: string, recreate: bool = false) =  
    if recreate:
        removeFile fn
    o.conn = db_sqlite.open(fn, "", "", "")
    if recreate:
        let script = parseSqlFile(PALITSA_SCHEMA_FILE)
        inTransaction(o):
            for i in script:
                #echo "executing '" & i & "'..."
                db_sqlite.exec o.conn, TSqlQuery(i)
            
    
    
proc closeDb*(o: var TOpenDb) =    
    o.conn.close()



proc genIdFor*(o: var TOpenDb, t: TPalTable, n = 1): TEntityId =
    ## generate id via id_seq table
    var nv = o.conn.getValue(sql"select nextv from id_seq where table_name = ?",
        $t)
    var id: int64
    if nv.parseBiggestInt(id) == 0:
        raise newException(EDb, "Failed to generate id for " & $t)
    
    result = toEntityId(id)
    o.conn.exec(sql"update id_seq set nextv = nextv + ? where table_name = ?", 
        $n, $t)
    


    
proc parseFileSize(s: string): int64 =
    try:
        result = parseInt64(s)
    except:
        raise newException(EInvalidValue, "failed parseFileSize for " & s)



proc createMedia*(o: var TOpenDb, name, path: string, scanTime: TTime): 
    tuple[mediaId, rootId: TEntityId] =
    # create media_desc, and root node
    result.mediaId = o.genIdFor(ptMediaDesc)
    result.rootId = o.genIdFor(ptDirEntryDesc)
    o.conn.exec(TSqlQuery("insert into ? (id, name, original_path, scan_time, "&
        "root_id) values(?,?,?,?,?);"), $ptMediaDesc, result.mediaId, name, 
        path, timeToSqlString(scanTime), result.rootId)
    
    o.conn.exec(TSqlQuery("insert into ? (id, parent_id, dir_path, name, "&
        "file_size, mtime, is_dir, desc_id) values(?,NULL,'','/',0,?,1, NULL);"), 
        $ptDirEntryDesc, result.rootId, timeToSqlString(scanTime))



proc createEntry*(o: var TOpenDb, e: var TDirEntryDesc): TEntityId {.discardable.}=
    ## Creates directory entry and updates id field. Returns this id field.
    result = o.genIdFor(ptDirEntryDesc)
    e.id = result
 
    if e.path == nil:
        e.path = ""
 
    o.conn.exec(TSqlQuery("insert into ? (id, parent_id, dir_path, name, "&
        "file_size, mtime, is_dir, desc_id) values(?,?,?,?,?,?,?,NULL);"), 
        $ptDirEntryDesc, result, e.parentId, e.path, e.name, e.fileSize, 
        timeToSqlString(e.mTime), boolToSql(e.isDir))
    

proc findMedia*(o: var TOpenDb, id: TEntityId, outM: var TMediaDesc): bool =
    result = false
    var row = o.conn.getRow(TSqlQuery("select name, original_path, scan_time, "&
        "root_id from ? where id = ?"), $ptMediaDesc, id)
    if row.len > 0:
        outM.id = id
        outM.name = row[0]
        outM.originalPath = row[1]
        outM.scanTime = timeFromSqlString(row[2])
        outM.rootId = parseId(row[3])
        return true
        
        
         
 
proc findEntry*(o: var TOpenDb, id: TEntityId, outE: var TDirEntryDesc): bool =
    result = false
    var row = o.conn.getRow(TSQLQuery("select name, dir_path, file_size, mtime,"&
        " is_dir, parent_id, desc_id from ? where id = ?"), $ptDirEntryDesc, id)
    if row.len > 0:
        outE.id = id
        outE.name = row[0]
        outE.path = row[1]
        outE.fileSize = parseFileSize(row[2])
        outE.mTime = timeFromSqlString(row[3])
        outE.isDir = parseSqlBool(row[4])
        outE.parentId = parseId(row[5])
        outE.descId = parseId(row[6])
        
        return true
# ------------


