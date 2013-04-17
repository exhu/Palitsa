# test dataset macro
import macros
import times

import palitsa_sqlutils

discard """

template dataSet(body: stmt): stmt {.immediate.}=
    template col*(f: expr, t: typedesc, c: string): stmt {.immediate.}=
        echo "ok"
        echo(astToStr(f) & astToStr(t) & c)
        
    body
    
# ------------
dataSet:
    col id, TEntityId, "id"
    col name, string, "name"
    col originalPath, string, "original_path"
    col scanTime, TTime, "scan_time"
    col rootId, TEntityId, "root_id"
    
"""

macro defDataset(stmts: stmt): stmt =
    nil
    
#template fieldCol(c: string, f: string, t: typedesc) =
#    nil

#dumpTree:
#    fieldCol "id", "id", TEntityId ## SQL=sss
    

{.pragma: id_sql.}
dumpTree:
    type
        TMyDs = object
            ## used for inserting new entries and querrying.
            ## FIELD ORDER IS IMPORTANT!
            id {.id_sql.}: TEntityId # SQL=id
            name: string # SQL=name
            originalPath: string # SQL=original_path
            scanTime: TTime # SQL=scan_time
            rootId: TEntityId # SQL=root_id

dumpTree:
    type 
        TDirEntryDesc* = tuple
            ## used for inserting new entries and querrying.
            ## FIELD ORDER IS IMPORTANT!
            id: TEntityId
            parentId: TEntityId
            path: string
            name: string
