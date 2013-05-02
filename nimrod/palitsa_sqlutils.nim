## sqlite3 dependent db utils

## use toSqlVal/fromSqlVal in your requests

import db_sqlite, strutils, parseutils, times
import typeinfo, tables

type
    TEntityId* = distinct int64
        ## table entry id holder, 0 = SQL NULL.
        ## use provided $, toInt64, toEntityId, parseId procs -- they
        ## convert to SQL string, int64, and vice versa.
    
    
    #    TDbEntity* = object of TObject
    #        ## represents a db table in native types
    #        id: TEntityId


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


proc parseId(s: string): TEntityId =
    ## converts empty, "NULL" etc strings to appropriate representation.
    var i: int64 = 0
    if parseBiggestInt(s, i) > 0:
        return toEntityId(i)
    if s == "" or s == "NULL" or s == "null":
        return NULL_ID
    raise newException(EInvalidValue, "Failed parseId for " & s)


proc toSqlVal*(e: string): string = e
proc fromSqlVal*(e: var string, s: string) = 
    e = s

proc toSqlVal*(e: TEntityId): string = return $e
proc fromSqlVal*(e: var TEntityId, s: string) = 
    e = parseId(s)


proc timeToSqlString(t: TTime): string =
    ## encodes time to SQL string/number, current implementation uses int64
    return $int64(t)

proc timeFromSqlString(s: string): TTime =
    ## decodes time from SQL result string/number, current implementation uses
    ## int64
    var i: int64
    if parseBiggestInt(s, i) > 0:
        return TTime(i)

    raise newException(EInvalidValue, "failed timeFromSqlString for " & s)



proc toSqlVal*(t: TTime): string = timeToSqlString(t)
proc fromSqlVal*(t: var TTime, s: string) =
    t = timeFromSqlString(s)



proc parseInt64(s: string): int64 =
    ## raises exception if can't parse
    var i: int64
    if parseBiggestInt(s, i) > 0:
        return i

    raise newException(EInvalidValue, "failed parseInt64 for " & s)


proc toSqlVal*(i: int64): string = $i
proc toSqlVal*(i: int): string = $i
proc toSqlVal*(i: int32): string = $i

proc fromSqlVal*(i: var int64, s: string) = 
    i = parseInt64(s)

proc fromSqlVal*(i: var int32, s: string) =
    var ip = parseInt64(s)
    if (ip < int32.low) or (ip > int32.high):
        raise newException(EOverflow, "fromSqlVal int32 overflow")
    else:
        i = int32(ip)

proc fromSqlVal*(i: var int, s: string) = 
    var ip = parseInt64(s)
    if (ip < int.low) or (ip > int.high):
        raise newException(EOverflow, "fromSqlVal int overflow")
    else:
        i = int(ip)



proc boolToSql(b: bool): string =
    ## stores bool as 0 or 1 integer
    if b == false:
        return "0"
    return "1"


proc parseSqlBool(s: string): bool =
    ## parses bool from integer string
    var i: int
    if parseInt(s, i) > 0:
        return i != 0

    raise newException(EInvalidValue, "failed parseSqlBool for " & s)



proc toSqlVal*(b: bool): string = boolToSql(b)
proc fromSqlVal*(b: var bool, s: string) = 
    b = parseSqlBool(s)



# -------


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



proc entityFieldsFromRow*[TT](t: var TT, row: seq[string]) =
    ## sets fields from t (except "id") by converting corresponding
    ## row items by type TT declaration order, where row is a result set.
    ## the "id" field must be not in the row result, it is ignored.
    var r = 0    
    for k,v in fieldPairs(t):
        # skip id field, it's not in result
        if k != "id":            
            v.fromSqlVal(row[r])
            r.inc
        
    assert(r == row.len)


proc entityFieldsFromRowAll*[TT](t: var TT, row: seq[string]) =
    ## sets fields from t by converting corresponding
    ## row items by type TT declaration order! row is the sql result set.
    var r = 0    
    for v in fields(t):
        v.fromSqlVal(row[r])
        r.inc
        
    assert(r == row.len)


proc countTabl*(o: var TOpenDb, tableName: string): int64 =
    ## Counts amount of rows for sql table stored in the db.
    ## t = table enum.
    var row = o.conn.getRow(sql"select count(*) from ?", tableName)
    result.fromSqlVal(row[0])


iterator iterateTabl*[TEnt](o: var TOpenDb, offset, 
    limit: int64): TEnt =
    ## iterate over all table rows.
    ## tableName = sql table name, desc = tuple.
    ## returns entities via *yield*.
    var e: TEnt
    for r in o.conn.rows(sql("select "& e.columnsString &
        " from ? limit ? offset ?"), e.tableName, limit, offset):
        e.entityFieldsFromRowAll(r)
        yield e


proc findRow*[TEnt](o: var TOpenDb, tableName: string,
    id: TEntityId, outM: var TEnt): bool =
    ## find table row by id.
    ## allFields = string of comma-separated sql column names.
    ## tableName = table sql name, outM = table row desc tuple.

    result = false
    var row = o.conn.getRow(sql("select "& outM.columnsString &
        " from ? where id = ?"), tableName, id)
    if row.len > 0:
        outM.entityFieldsFromRowAll(row)
        return true


proc indexOf*(t: typedesc, name: string): int  {.compiletime.} =
    ## takes a tuple and looks for the field by name.
    ## returs index of that field.
    var 
        d: t
        i = 0
    for n, x in fieldPairs(d): 
        if n == name: return i
        i.inc
        
    raise newException(EInvalidValue, "No field " & name & " in type " & astToStr(t))


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
