## sqlite3 dependent db utils

import db_sqlite, strutils, parseutils, times
import typeinfo

type
    TEntityId* = distinct int64
        ## table entry id holder, 0 = SQL NULL.
        ## use provided $, toInt64, toEntityId, parseId procs -- they
        ## convert to SQL string, int64, and vice versa.
    
    TDbEntity = object of TObject
        ## represents a db table in native types
        id: TEntityId
        
    
    EMultiTransaction* = object of EDB
        ## begin transaction within already running transaction error.

    TOpenDb* = object
        ## use DB via this structure
        conn*: TDbConn
        inTransaction: bool

proc `<` * (x, y: TEntityId): bool {.borrow.}
proc `<=` * (x, y: TEntityId): bool {.borrow.}
proc `==` * (x, y: TEntityId): bool {.borrow.}
proc toInt64*(x: TEntityId): int64 = int64(x)
proc toEntityId*(x: int64): TEntityId = TEntityId(x)

const
    NULL_ID* : TEntityId = toEntityId(0'i64)
    ## we treat zero ID as SQL NULL. 
    ## So zero ID is never used to identify an existing row!

proc `$`* (x: TEntityId): string =
    ## converts 0 to "NULL"
    if x == NULL_ID:
        return "NULL"
    return $toInt64(x)
    
    
proc parseId*(s: string): TEntityId =
    ## converts empty, "NULL" etc strings to appropriate representation.
    var i: int64 = 0
    if parseBiggestInt(s, i) > 0:
        return toEntityId(i)
    if s == "" or s == "NULL" or s == "null":
        return NULL_ID
    raise newException(EInvalidValue, "Failed parseId for " & s)


proc timeToSqlString*(t: TTime): string =
    ## encodes time to SQL string/number, current implementation uses int64
    return $int64(t)


proc parseInt64*(s: string): int64 =
    ## raises exception if can't parse
    var i: int64
    if parseBiggestInt(s, i) > 0:
        return i
    
    raise newException(EInvalidValue, "failed parseInt64 for " & s)


proc boolToSql*(b: bool): string =
    ## stores bool as 0 or 1 integer
    if b == false:
        return "0"
    return "1"


proc parseSqlBool*(s: string): bool =
    ## parses bool from integer string
    var i: int
    if parseInt(s, i) > 0:
        return i != 0
    
    raise newException(EInvalidValue, "failed parseSqlBool for " & s)
 


proc timeFromSqlString*(s: string): TTime =
    ## decodes time from SQL result string/number, current implementation uses 
    ## int64
    var i: int64
    if parseBiggestInt(s, i) > 0:
        return TTime(i)
        
    raise newException(EInvalidValue, "failed timeFromSqlString for " & s)
 


proc beginTransaction*(o: var TOpenDb)
proc endTransaction*(o: var TOpenDb, rollback: bool = false)

template InTransaction*(o: var TOpenDb, rollback:bool, stmts: stmt) =
    ## rollbacks on exception and reraises error.
    ## you can force rollback by rollback = true, e.g. for testing
    o.beginTransaction
    try:
      stmts
      o.endTransaction(rollback)
    except:
      o.endTransaction(true)
      raise


template InTransaction*(o: var TOpenDb, stmts: stmt) =
    ## rollbacks on exception and reraises error, commits on success.
    InTransaction(o, rollback = false):
        stmts



proc beginTransaction*(o: var TOpenDb) =
    if o.inTransaction:
        raise newException(EMultiTransaction, "already in transaction!")
        
    o.conn.exec sql"begin transaction;"
    o.inTransaction = true



proc endTransaction*(o: var TOpenDb, rollback: bool = false) =
    if not rollbacK:
        o.conn.exec sql"commit;"
    else:
        o.conn.exec sql"rollback;"
        
    o.inTransaction = false



# ---------- sql parsing -------

type
    TStatements* = seq[string]
        ## sql complete statements for execution one by one.

    RSqlParser = ref object
        statements : TStatements
        curStatement: string

proc parseLine(p : RSQLParser, s: string) =
    var
        inComments = false
        possibleComments = false
        
    for i in items(s):
        if inComments:
            continue

        if (i == ';') and (inComments == false):
            p.statements.add(p.curStatement)
            p.curStatement = ""
            continue
        
            
        if i == '-':
            if possibleComments:
                inComments = true
                possibleComments = false
                continue
            else:
                possibleComments = true
                continue
        else:
            if possibleComments:
                possibleComments = false
                p.curStatement &= "-"
                
        p.curStatement &= $i

            
    
        
proc ParseSqlFile*(fn : string) : TStatements =
    ## reads sql script and splits it into statements
    var p : RSqlParser
    new(p)
    p.curStatement = ""
    p.statements = @[]
    var f = open(fn)
    var line: string = ""
    while f.readLine(line):
        p.parseLine(line)
    close(f)
    return p.statements
 
# -----
 
# TODO implement simple find/create/delete/update procs based on typeinfo
# for plain data objects, raise exception if field type is object etc.
# special case for id field, boolean type etc.

#iterator treeFields(obj: TAny): tuple[name: string, any: TAny] =
#    for k,v in fields(obj):
#        yield (k,v)
#    
#    if obj.baseTypeKind == akObject:
#        for k,v in treeFields(obj.base):
#            yield k,v
 
type 
    TAKField = tuple[name: string, any: TAny]
    

proc forEveryField(o: TAny, p: proc(f: TAKField)) =
    for n, a in o.fields:
        p((n,a))
        
    if o.baseTypeKind == akObject:
        forEveryField(o.base, p)


proc getAllFields(o: TAny): seq[TAKField] =
    var coll: seq[TAKField] = @[]
    o.forEveryField proc(f:TAKField) =
        coll.add f
    return coll
    
    
proc parseInt32(s: string): int32 =
    var i: BiggestInt = 0
    discard parseBiggestInt(s, i)
    if i >= low(int32) and i <= high(int32):
        return int32(i)
    raise newException(EInvalidValue, s & " is beyond int32 range")
    

proc readObject*(o: var TOpenDb, tabName: string, obj: TAny): bool =
    ## gets id field, reads it value and looks for this object in
    ## the specified table. returns true on success
    var 
        fields = getAllFields(obj)
        id: TEntityId = NULL_ID
        fieldsStr: seq[string] = @[]
        
        
    for f in fields:
        if f.name == "id":
            assert(f.any.size == TEntityId.sizeof)
            id = toEntityId(f.any.getInt64())
        
        fieldsStr.add($f.name)
            
    # select queryStr from tabName where id = $id
    var fieldsQ = repeatStr(fields.len, "?,")
    # cut last ','
    fieldsQ.setLen(fieldsQ.len-1)
    var row = o.conn.getRow(TSqlQuery("select " & fieldsQ & " from ? where id = ?"),
        fieldsStr & @[tabName, $id])
    
    # fill obj fields from row, not all types are supported
    block:
        var fIndex: int = 0
        for r in row:
            var f = fields[fIndex]
            inc fIndex
            
            case f.any.kind
            of akInt32:
                f.any.setBiggestInt(parseInt32(r))
                
            of akInt64:
                if r == "":
                    f.any.setBiggestInt(0)
                else:
                    f.any.setBiggestInt(parseInt64(r))
                    
            of akBool:
                f.any.setBiggestInt(int(parseSqlBool(r)))
                
            of akString:
                f.any.setString(r)
            else:
                raise newException(EInvalidValue, "can't parse field " & f.name & " of type " & $f.any.kind)
                
    return false
    

proc insertObject*(o: var TOpenDb, tabName: string, obj: TAny, entityFields: openArray[string]) =
    ## id field must be valid! entityFields = list of field names which are of type TEntityId
    ## for correct NULL value handling.
    var 
        fields = getAllFields(obj)
        fieldsStr: seq[string] = @[]
        valuesStr: seq[string] = @[]
    
    
    for f in fields:
        fieldsStr.add(f.name)
        if entityFields.contains(f.name) or f.name == "id":
            valuesStr.add($toEntityId(f.any.getBiggestInt()))
        else:
            var s: string
            case f.any.kind
            of akInt32, akInt64:
                s = $f.any.getBiggestInt()
            of akString:
                s = f.any.getString()
            of akBool:
                s = boolToSql(f.any.getBool())
            else:
                raise newException(EInvalidValue, "no support for " & $f.any.kind)
            
            valuesStr.add(s)
        
    #"insert into ? (" & fieldsStr & ") values (" & 
    var fieldsQ = repeatStr(fields.len, "?,")
    # cut out last ','
    fieldsQ.setLen(fieldsQ.len-1)
    o.conn.exec(sql("insert into ? (" & fieldsQ & ") values (" & fieldsQ & ");"),
        fieldsStr & valuesStr)

proc updateObject*(o: var TOpenDb, tabName: string, obj: TAny, entityFields: openArray[string]) =
    nil
    # TODO reuse code from insertObject,
    # update ? set ? = ?, ... where id = ?

 
# ------------------
        
when isMainModule:
    # var st : TStatements 
    # st = ParseSqlFile("db_schema1_sqlite.sql") 
    # for s in items(st):
    # echo s
    type TMy = object of TDbEntity
        nnn: string
        
    var t: TMy
    var r = t.toAny.getAllFields
    for i in items(r):
        echo i.name