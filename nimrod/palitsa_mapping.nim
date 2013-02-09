import strutils, parseutils, times
import typeinfo, tables


type
    PFieldCoder* = ref object
        ## serialize-like functions, converts from sql and to sql text
        toString: proc (a: TAny): string {.closure.}
        fromString: proc (a: var TAny, s: string) {.closure.}

    TEntityCoder* = TTable[string, PFieldCoder]
        ## maps field names to serialize methods
        ## id field is not specified here. Pass this map to readObject etc.
        ## functions.
        
# ---------------        
        
proc newFieldCoder*(o: var PFieldCoder, toString: proc(a: TAny): string {.closure.},
    fromString: proc(a: var TAny, s: string) {.closure.}) =
    o.new
    o.toString = toString
    o.fromString = fromString


var defEntCoder: PFieldCoder = nil

proc DefaultEntityIdCoder*(): PFieldCoder =
    ## converts between SQL NULL, primary key and TEntityId
    if defEntCoder != nil:
        return defEntCoder
        
    defEntCoder.new
    defEntCoder.toString = proc(a: TAny): string =
        assert(a.size == TEntityId.sizeof)
        return $toEntityId(a.getInt64())
        
    defEntCoder.fromString = proc(a: var TAny, s: string)=
        assert(a.size == TEntityId.sizeof)
        var id = parseId(s)
        a.setBiggestInt(toInt64(id))
        return
        
    return defEntCoder
    

var defTimeCoder: PFieldCoder = nil

proc DefaultTimeCoder*(): PFieldCoder =
    ## converts to/from encoded TTime for SQL.
    if defTimeCoder != nil:
        return defTimeCoder
        
    defTimeCoder.new
    defTimeCoder.toString = proc(a: TAny): string =
        assert(a.size == TTime.sizeof)
        return timeToSqlString(TTime(a.getBiggestInt()))
        
    defTimeCoder.fromString = proc(a: var TAny, s: string)=
        assert(a.size == TTime.sizeof)
        var t = parseInt64(s)
        a.setBiggestInt(t)
        return
        
    return defTimeCoder

# ------------



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


# TODO use TEntityCoder

proc readObject*(o: var TOpenDb, tabName: string, obj: TAny): bool =
    ## gets id field, reads its value and looks for this object in
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
                raise newException(EInvalidValue, "can't parse field " &
                    f.name & " of type " & $f.any.kind)

    return false





proc anyToFieldsValues*(obj: TAny, entityFields: openArray[string]):
    tuple[ fieldsNames: seq[string], fieldsValues: seq[string] ] =
    ## grabs field names into a sequence and values converted into
    ## strings.

    var
        fields = getAllFields(obj)
        fieldsStr: seq[string] = @[]
        valuesStr: seq[string] = @[]


    for f in fields:
        fieldsStr.add(f.name)
        var isIdField = (f.name == "id")
        var isEntityField = entityFields.contains(f.name)


        if isEntityField or isIdField:
            var v = toEntityId(f.any.getBiggestInt())
            if isIdField:
                assert(v != NULL_ID)

            valuesStr.add($v)
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

    result.fieldsNames = fieldsStr
    result.fieldsValues = valuesStr


proc insertObject*(o: var TOpenDb, tabName: string, obj: TAny, entityFields: openArray[string]) =
    ## id field must be valid! entityFields = list of field names which are of type TEntityId
    ## for correct NULL value handling.
    ## NOTE time/date type is defined as SLONGWORD in C and as "int" in nimrod
    ## and it can be either int32 or int64

    var namesValues = anyToFieldsValues(obj, entityFields)

    # TODO use anyToFieldsValues

    var
        fields = getAllFields(obj)
        fieldsStr: seq[string] = @[]
        valuesStr: seq[string] = @[]


    for f in fields:
        fieldsStr.add(f.name)
        var isIdField = (f.name == "id")
        var isEntityField = entityFields.contains(f.name)


        if isEntityField or isIdField:
            var v = toEntityId(f.any.getBiggestInt())
            if isIdField:
                assert(v != NULL_ID)

            valuesStr.add($v)
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
