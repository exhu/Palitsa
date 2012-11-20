import times, parseutils, unittest

import palitsa_db

suite "db open suite":
    var myDb: TOpenDb
    setup:
        echo "suite setup"
        myDb.openDb("ttt.db", recreate = true)
    
    
    teardown:
        echo "suite teardown"
        myDb.closeDb()

    test "double transaction fail":
        myDb.beginTransaction
        try:
            myDb.beginTransaction
        except EMultiTransaction:
            nil
        
        finally:
            myDb.endTransaction(rollback = true)


    test "genId":
        inTransaction(myDb):
            var id1 = myDb.genIdFor(ptMediaDesc)
            check toInt64(id1) > 0'i64
            var id2 = myDb.genIdFor(ptMediaDesc)
            check toInt64(id2) > 1'i64
            
    test "genId fail rollback":
        var idBeforeFail: TEntityId
        inTransaction(myDb, rollback = true):
            idBeforeFail = myDb.genIdFor(ptMediaDesc)
        inTransaction(myDb, rollback = true):
            var id = myDb.genIdFor(ptMediaDesc)
            check BiggestInt(id) == BiggestInt(idBeforeFail)

    test "createMedia, entry, findMedia":
        var 
            mediaId, entId: TEntityId
            
            
        inTransaction(myDb):
            var t: TTime
            var m = myDb.createMedia("name", "path", t)
            echo "mediaId  = " & $m.mediaId & ", rootId = " & $m.rootId
            mediaId = m.mediaId
            
            var e: TDirEntryDesc
            e.parentId = m.rootId
            e.name = "test file"
            echo "entry id = " & $myDb.createEntry(e)
            entId = e.id
            
        var me: TMediaDesc
        var res = findMedia(myDb, mediaId, me)
        check res == true
        check me.name == "name"
        echo "original path = " & me.originalPath
        
        var dire: TDirEntryDesc
        res = findEntry(myDb, entId, dire)
        check res == true
        check dire.name == "test file"
            
        
    test "time storage":
        # TTime <> int64 test

        var t = GetTime()
        echo "template time = " & $t
        var s = timeToSqlString(t)
        t = timeFromSqlString(s)
        echo "encoded/decoded time = " & $t
        
            

echo "null = " & $toEntityId(0)
