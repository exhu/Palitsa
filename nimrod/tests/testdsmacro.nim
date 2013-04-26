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

template ensureNode(a, e: TNimrodNodeKind) : stmt =
    if e != a:
        
        echo("expected " & $e & " got " & $a & " at " & $InstantiationInfo())
        raise newException(EInvalidValue, "wrong expression")
        #{. fatal: "expected" .}

macro defDataset(stmts: stmt): stmt {.immediate.}=
    # okay, stmts = nnkStmtList
    #ensureNode(stmts[0].kind, nnkTypeSection)
    # find nnkTypeDef, read son ident
    # find nnkObjectTy node
    # replace with tuple
    # read nnkPragma as ObjectTy son, read Ident as son of nnkPragma
    # replace nnkPragma with nnkEmpty
    
    # find IdentDefs, if son = PragmaExpr, then parse field name from it
    
    result = stmts
    
#template fieldCol(c: string, f: string, t: typedesc) =
#    nil

#dumpTree:
#    fieldCol "id", "id", TEntityId ## SQL=sss
    

{.pragma: id_sql.}
{.pragma: my_ds_table.}
#dumpTree:
defDataSet:
    # abc
    type
        TMyDs = object {.my_ds_table.}
            ## used for inserting new entries and querrying.
            ## FIELD ORDER IS IMPORTANT!
            id {.id_sql.}: TEntityId # SQL=id
            name: string # SQL=name
            originalPath: string # SQL=original_path
            scanTime: TTime # SQL=scan_time
            rootId: TEntityId # SQL=root_id



# tuples do not support pragmas attached to fields, desired result
discard """
#dumpTreeImm:
    type 
        TDirEntryDesc* = tuple
            ## used for inserting new entries and querrying.
            ## FIELD ORDER IS IMPORTANT!
            id: TEntityId
            parentId: TEntityId
            path: string
            name: string
            
    const
        DirEntryDescTableName = "my_ds_table"
        DirEntryDescTableColumns = ["id_sql", "name"]
        DirEntryDescTableColumnsString = "id_sql,name"
        
    proc tableName*(t: TDirEntryDesc): string {.inline.} =
        ## returns the sql name of the table that t maps to.
        return DirEntryDescTableName
        
    proc columns*(t: TDirEntryDesc): array of string {.inline.} =
        ## returs array of column names
        return DirEntryDescTableColumns
        
    proc columnsString*(t: TDirEntryDesc): string {.inline.} =
        ## returns comma separated string of column names
        return DirEntryDescTableColumnsString

"""

discard """
StmtList
  TypeSection
    TypeDef
      Ident !"TMyDs"
      Empty
      ObjectTy
        Empty
        Empty
        RecList
          IdentDefs
            PragmaExpr
              Ident !"id"
              Pragma
                Ident !"id_sql"
            Ident !"TEntityId"
            Empty
          IdentDefs
            Ident !"name"
            Ident !"string"
            Empty
          IdentDefs
            Ident !"originalPath"
            Ident !"string"
            Empty
          IdentDefs
            Ident !"scanTime"
            Ident !"TTime"
            Empty
          IdentDefs
            Ident !"rootId"
            Ident !"TEntityId"
            Empty
StmtList
  TypeSection
    TypeDef
      Postfix
        Ident !"*"
        Ident !"TDirEntryDesc"
      Empty
      TupleTy
        IdentDefs
          Ident !"id"
          Ident !"TEntityId"
          Empty
        IdentDefs
          Ident !"parentId"
          Ident !"TEntityId"
          Empty
        IdentDefs
          Ident !"path"
          Ident !"string"
          Empty
        IdentDefs
          Ident !"name"
          Ident !"string"
          Empty
"""
