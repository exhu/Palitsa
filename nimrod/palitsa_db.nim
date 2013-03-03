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
    ## Enums to define table
    ## names as in the SQL schema.
    


    TDirEntryDesc* = tuple
        ## used for inserting new entries and querrying.
        ## FIELD ORDER IS IMPORTANT!
        id: TEntityId
        name, path: string
        fileSize: int64
        mTime: TTime
        isDir: bool
        parentId: TEntityId
        descId: TEntityId

    TMediaDesc* = tuple
        ## used for inserting new entries and querrying.
        ## FIELD ORDER IS IMPORTANT!
        id: TEntityId
        name: string
        originalPath: string
        scanTime: TTime
        rootId: TEntityId



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
    # todo check for proper version number
            
    
    
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
    


proc createMedia*(o: var TOpenDb, name, path: string, scanTime: TTime): 
    tuple[mediaId, rootId: TEntityId] =
    ## Creates media_desc, and root node and returs the IDs.
    result.mediaId = o.genIdFor(ptMediaDesc)
    result.rootId = o.genIdFor(ptDirEntryDesc)
    o.conn.exec(TSqlQuery("insert into ? (id, name, original_path, scan_time, "&
        "root_id) values(?,?,?,?,?);"), $ptMediaDesc, result.mediaId.toSqlVal, 
        name.toSqlVal, 
        path.toSqlVal, 
        scanTime.toSqlVAL, result.rootId.toSqlVal)
    
    
    
    o.conn.exec(TSqlQuery("insert into ? (id, parent_id, dir_path, name, "&
        "file_size, mtime, is_dir, desc_id) values(?,NULL,'','/',0,?,1, NULL);"
        ), $ptDirEntryDesc, result.rootId.toSqlVal, scanTime.toSqlVal)



proc createEntry*(o: var TOpenDb, e: var TDirEntryDesc): TEntityId {.
    discardable .}=
    ## Creates directory entry and updates id field. Returns this id field.
    ## descId field is set to NULL_ID !
    result = o.genIdFor(ptDirEntryDesc)
    e.id = result
    e.descId = NULL_ID    
 
    if e.path == nil:
        e.path = ""
 
    o.conn.exec(TSqlQuery("insert into ? (id, parent_id, dir_path, name, "&
        "file_size, mtime, is_dir, desc_id) values(?,?,?,?,?,?,?,NULL);"), 
        $ptDirEntryDesc, result.toSqlVal, e.parentId.toSqlVal, 
        e.path.toSqlVal, e.name.toSqlVal, e.fileSize.toSqlVal, 
        e.mTime.toSqlVal, e.isDir.toSqlVal)
    


proc findMedia*(o: var TOpenDb, id: TEntityId, outM: var TMediaDesc): bool =
    ## Read media by id, return false if no such media
    result = false
    var row = o.conn.getRow(TSqlQuery("select name, original_path, scan_time, "&
        "root_id from ? where id = ?"), $ptMediaDesc, id)
    if row.len > 0:
        outM.id = id        
        outM.entityFieldsFromRow(row)        
        return true
              
 
proc findEntry*(o: var TOpenDb, id: TEntityId, outE: var TDirEntryDesc): bool =
    ## Read entry by id, return false if no such entry
    result = false
    var row = o.conn.getRow(TSQLQuery(
        "select name, dir_path, file_size, mtime," &
        " is_dir, parent_id, desc_id from ? where id = ?"), $ptDirEntryDesc, 
        id)
    if row.len > 0:
        outE.id = id        
        outE.entityFieldsFromRow(row)                        
        return true
        
        
# ------------


