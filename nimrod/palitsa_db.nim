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
        
    TPalTable* = enum ## Enums to define table \
        ## names as in the SQL schema, used by id generator and other utils.
        ptMediaDesc = "media_desc", ## media
        ptDirEntryDesc = "dir_entry_desc",  ## file or directory
        ptTextDesc = "text_desc", ## text description
        ptTagDesc = "tag_desc", ## tags
        ptTagDirEntryAssoc = "tag_dir_entry_assoc" ## tags and dir associations
    
    
    TDirEntryDesc* = tuple ## \
        ## used for inserting new entries and querrying.
        ## FIELD ORDER IS IMPORTANT!
        id: TEntityId
        parentId: TEntityId
        path: string
        name: string
        fileSize: int64
        mTime: Time
        isDir: bool
        descId: TEntityId 

    TMediaDesc* = tuple ## \
        ## used for inserting new entries and querrying.
        ## FIELD ORDER IS IMPORTANT!
        id: TEntityId
        name: string
        originalPath: string
        scanTime: Time
        rootId: TEntityId
        
# -----
proc columnsString(m: TMediaDesc): string =
    ## returns comma-separated field names as a string
    return "id,name,original_path,scan_time,root_id"
    
proc columnsString(d: TDirEntryDesc): string =
    ## returns comma-separated field names as a string
    return "id,parent_id,dir_path,name,file_size,"&
        "mtime,is_dir,desc_id"

proc tableName(m: TMediaDesc): string =
    return $ptMediaDesc

proc tableName(d: TDirEntryDesc): string =
    return $ptDirEntryDesc

# --------

proc openDb*(o: var TOpenDb, fn: string, recreate: bool = false) =  
    if recreate:
        removeFile fn
    o.conn = db_sqlite.open(fn, "", "", "")
    if recreate:
        let script = parseSqlFile(PALITSA_SCHEMA_FILE)
        o.inTransaction():
            for i in script:
                #echo "executing '" & i & "'..."
                let q = sql(i)
                db_sqlite.exec(o.conn, q)
    
    # check for proper version number
    var ver = db_sqlite.getValue(o.conn, sql"select version_num from db_desc")
    var iv: int
    iv.fromSqlVal(ver)
    if iv != PALITSA_SCHEMA_VERSION_INT:
        raise newException(EDb, 
            "Database ($1) does not match schema version $2".format( 
             iv, PALITSA_SCHEMA_VERSION_INT))
    
    
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
    


proc createMedia*(o: var TOpenDb, name, path: string, scanTime: Time): 
    tuple[mediaId, rootId: TEntityId] =
    ## Creates media_desc, and root node and returs the IDs.
    result.mediaId = o.genIdFor(ptMediaDesc)
    result.rootId = o.genIdFor(ptDirEntryDesc)
    o.conn.exec(sql("insert into ? (id, name, original_path, scan_time, "&
        "root_id) values(?,?,?,?,?);"), $ptMediaDesc, result.mediaId.toSqlVal, 
        name.toSqlVal, 
        path.toSqlVal, 
        scanTime.toSqlVAL, result.rootId.toSqlVal)
    
    
    
    o.conn.exec(sql("insert into ? (id, parent_id, dir_path, name, "&
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
 
    o.conn.exec(sql("insert into ? (id, parent_id, dir_path, name, "&
        "file_size, mtime, is_dir, desc_id) values(?,?,?,?,?,?,?,NULL);"), 
        $ptDirEntryDesc, result.toSqlVal, e.parentId.toSqlVal, 
        e.path.toSqlVal, e.name.toSqlVal, e.fileSize.toSqlVal, 
        e.mTime.toSqlVal, e.isDir.toSqlVal)
    


proc findMedia*(o: var TOpenDb, id: TEntityId, outM: var TMediaDesc): bool =
    ## Read media by id, return false if no such media
    return findRow(o, outM.tableName, id, outM)


proc findMediaByName*(o: var TOpenDb, name: string, 
    outM: var TMediaDesc): bool =
    ## Read media by id, return false if no such media

    var row = o.conn.getRow(sql("select "& outM.columnsString &
        " from ? where name = ?"), outM.tableName, name)

    if row.len > 0 and row[0].len > 0:
        outM.entityFieldsFromRowAll(row)
        return true

    return false


proc findEntry*(o: var TOpenDb, id: TEntityId, outE: var TDirEntryDesc): bool =
    ## Read entry by id, return false if no such entry
    return findRow(o, outE.tableName, id, outE)
        
        
# ------------

        
proc countMedia*(o: var TOpenDb): int64 =
    ## Counts amount of media sources stored in the db.
    return countTabl(o, $ptMediaDesc)


iterator iterateMedia*(o: var TOpenDb, offset, limit: int64): TMediaDesc =
    ## iterate over all media descriptors
    for e in iterateTabl[TMediaDesc](o, offset, 
        limit):
        yield e
    
iterator iterateMedia*(o: var TOpenDb): TMediaDesc =
    ## iterate over all media descriptors
    for e in iterateTabl[TMediaDesc](o):
        yield e
 
proc countDirEntry*(o: var TOpenDb): int64 =
    ## Counts amount of directory entries stored in the db.
    return countTabl(o, $ptDirEntryDesc)


iterator iterateDirEntry*(o: var TOpenDb, offset, limit: int64): TDirEntryDesc =
    ## iterate over all dir entries
    for e in iterateTabl[TDirEntryDesc](o, offset, limit):
        yield e

iterator iterateDirEntryByParent*(o: var TOpenDb, parent: TEntityId, 
    offset, limit: int64): TDirEntryDesc =
    ## iterate over all table rows where parent = specified one.
    for e in iterateTablWhere[TDirEntryDesc](o, offset, limit, "parent_id = " &
        $parent):
            yield e


iterator iterateDirEntryByParent*(o: var TOpenDb, 
    parent: TEntityId): TDirEntryDesc =
    ## iterate over all table rows where parent = specified one.
    for e in iterateTablWhere[TDirEntryDesc](o, "parent_id = " &
        $parent):
            yield e

proc findMediaIdFromDirEntryId*(o: var TOpenDb, 
    dirEntryId: TEntityId): TEntityId =
    ## hierarchically find the root and get media desc id
    var dent: TDirEntryDesc
    var nextId = dirEntryId
    
    while nextId != NULL_ID:
        if o.findEntry(nextId, dent) == false:
            raise newException(EDb, "No direntry for id = " & $dirEntryId)        
        nextId = dent.parentId
    
    var row = o.conn.getRow(sql"select id from ? where root_id = ?", 
        $ptMediaDesc, dent.id)
        
    result.fromSqlVal(row[0])
    


