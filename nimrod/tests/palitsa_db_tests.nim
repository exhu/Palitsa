import times, parseutils, unittest, os

import logging, palitsa_sqlutils, palitsa_db, palitsa_scan, palitsa_db_scan

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
        
            
    test "countMedia, dirEntry, findMediaIdFromDirEntryId":
        var res = countMedia(myDb)
        check res == 0
        
        var 
            rootToFind: TEntityId
            medToFind: TEntityId
            
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
            rootToFind = m.rootId
            medToFind = m.mediaId
            
            
        res = countMedia(myDb)
        check res == 2
        
        
        # root entries + one custom
        res = countDirEntry(myDb)
        check res == 3
        
        var foundId = myDb.findMediaIdFromDirEntryId(rootToFind)
        check foundId == medToFind
    

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
        #echo "indexOf test disabled!"
        let r = TMediaDesc.indexOf("originalPath")
        check r == 2
        
    test "scan":
        createDir("tempdir")
        createDir("tempdir/tempdir1")
        createDir("tempdir/tempdir2")
        createDir("tempdir/tempdir2/tempdir3")
        
        let filesToCreate = ["tempdir/fl1.a", "tempdir/fl2.b",
            "tempdir/tempdir2/fl3.e", "tempdir/tempdir2/tempdir3/fl4.f"]
        
        var f: TFile
        
        for fn in filesToCreate:
            assert(f.open(fn, fmWrite))
            f.close()
        
        # scan and compare with
        var found: array[0..filesToCreate.high, bool]
        for i in found.low..found.high: found[i] = false
        
        var si: TScanIface
        si.onNewFile = proc(fn: string) =
            var i = filesToCreate.find(fn)
            if i >= 0:
                found[i] = true
                
        si.onEnterDir = proc(fn: string) =
            return
                
        si.onLeaveDir = proc(fn: string) =
            return
        
        scanPath("tempdir", si)
        
        var foundCounter: int
        for i in found:
            foundCounter.inc
                    
        check foundCounter == filesToCreate.len
        removeDir("tempdir")
        
    test "addFsTree":
        createDir("tempdir")
        createDir("tempdir/tempdir1")
        createDir("tempdir/tempdir2")
        createDir("tempdir/tempdir2/tempdir3")
        
        let dirsCount = 4
        
        let filesToCreate = ["tempdir/fl1.a", "tempdir/fl2.b",
            "tempdir/tempdir2/fl3.e", "tempdir/tempdir2/tempdir3/fl4.f"]
            
        block:
            var f: TFile
        
            for fn in filesToCreate:
                assert(f.open(fn, fmWrite))
                f.close()
        
        var (media, root) = myDb.createMedia("tempdir", "tempdir", getTime())
        
        myDb.addFsTree(root, "tempdir")
        
        removeDir("tempdir")
        
        var 
            mcount = myDb.countMedia()
            ecount = myDb.countDirEntry()
            
        check mcount == 1
        check ecount == (dirsCount + filesToCreate.len)
        
        let searchFn = filesToCreate[filesToCreate.high].extractFilename()
        var found = false
        let testParent = "tempdir2"
        let testChild = "fl3.e"
        var testParentId: TEntityId
        
        for i in myDb.iterateDirEntry(0, ecount):
            if searchFn == i.name:
                found = true
                echo i.name
                
            if i.name == testParent:
                testParentId = i.id
                
        check found == true
        check testParentId != NULL_ID
        
        var foundChild = false
        for i in myDb.iterateDirEntryByParent(testParentId, 0, ecount):
            if i.name == testChild:
                foundChild = true

        check foundChild == true
        
    test "dir tree enum":
        # TODO enumerate tree
        var media = [("tempdir", false), ("dd2", false), ("m m3", false)]
        for i in media:
            discard myDb.createMedia(i[0], "tempdir", getTime())
            
        # TODO enumerate and set flag field to true
        
#echo "null = " & $toEntityId(0)

