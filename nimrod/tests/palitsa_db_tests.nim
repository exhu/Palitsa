import times, parseutils, unittest

import palitsa_sqlutils, palitsa_db

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
        echo "find entry..."
        res = findEntry(myDb, entId, dire)
        echo "fount entry..."
        check res == true
        assert(not dire.name.isNil)
        check dire.name == "test file"
        
            
        
    test "time storage":
        # TTime <> int64 test

        var t = GetTime()
        echo "template time = " & $t
        var s = t.toSqlVal
        t.fromSqlVal(s)
        echo "encoded/decoded time = " & $t
        
            
    test "countMedia, dirEntry":
        var res = countMedia(myDb)
        check res == 0
            
        inTransaction(myDb):
            var t: TTime
            var m = myDb.createMedia("name", "path", t)
            echo "mediaId  = " & $m.mediaId & ", rootId = " & $m.rootId
            
            res = countMedia(myDb)
            check res == 1
            
            # one root entry per media at least
            res = countDirEntry(myDb)
            check res == 1
            
            var e: TDirEntryDesc
            e.name = "testtt"
            e.parentId = m.rootId
            myDb.createEntry(e)
            
            m = myDb.createMedia("name2", "path2", t)
            echo "mediaId  = " & $m.mediaId & ", rootId = " & $m.rootId
            
            
        res = countMedia(myDb)
        check res == 2
        
        
        # root entries + one custom
        res = countDirEntry(myDb)
        check res == 3
    

    test "iterateMedia, dirEntry":
            
        inTransaction(myDb):
            var t: TTime
            var m = myDb.createMedia("name1", "path1", t)
            m = myDb.createMedia("name2", "path2", t)
        
        var 
            cnt = myDb.countMedia
            found: seq[string] = @[]
            
        #found.newSeq
        for m in myDb.iterateMedia(offset = 0, limit = cnt):
            found.add(m.name)
            echo m.name & ", " & m.originalPath
            
        check found.len == 2
        check found.contains("name1") == true
        check found.contains("name2") == true
        
        var iterEntries = 0
        for e in myDb.iterateDirEntry(offset = 0, limit = cnt):
            iterEntries.inc
            
        check iterEntries == 2
        
        
    test "indexOf":
        const r = indexOf(TMediaDesc, "path")
        check r == 2

echo "null = " & $toEntityId(0)
