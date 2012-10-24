# db access
import db_sqlite
import times
# ----
import sqlutils

const
    PALITSA_SCHEMA_FILE = "db_schema1_sqlite.sql"
    PALITSA_SCHEMA_VERSION_INT = 103

type
    TEntityId* = int64
    TOpenDb* = object
        conn: TDbConn
        
    TPalTable = enum
        ptMediaDesc = "media_desc",
        ptDirEntryDesc = "dir_entry_desc",
        ptTextDesc = "text_desc",
        ptTagDesc = "tag_desc",
        ptTagDirEntryAssoc = "tag_dir_entry_assoc"


proc genIdFor(o: TOpenDb, t: TPalTable): TEntityId =
  # TODO generate id via id_seq table

proc createMedia*(o: TOpenDb, name, path: string, scanTime: TTime): tuple[mediaId, rootId: TEntityId] =
  # TODO create media_desc, and root node

proc createEntry(o: TOpenDb, name, path: string, fileSize: int64, mTime: TTime, isDir: bool): TEntityId =
    # TODO
    
    
