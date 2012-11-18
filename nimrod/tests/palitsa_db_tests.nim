import times

import palitsa_db, unittest

suite "db open suite":
    var myDb: TOpenDb
    setup:
        echo "suite setup"
        myDb.openDb("ttt.db", recreate = true)
    
    
    teardown:
        echo "suite teardown"
        myDb.closeDb()
    
    test "genId":
        inTransaction(myDb):
            var id1 = myDb.genIdFor(ptMediaDesc)
            check id1 > 0'i64
            var id2 = myDb.genIdFor(ptMediaDesc)
            check id2 > 1'i64
            
    test "genId fail rollback":
        var idBeforeFail: TEntityId
        inTransaction(myDb, rollback = true):
            idBeforeFail = myDb.genIdFor(ptMediaDesc)
        inTransaction(myDb, rollback = true):
            var id = myDb.genIdFor(ptMediaDesc)
            check BiggestInt(id) == BiggestInt(idBeforeFail)

    test "createMedia":
        var t: TTime
        var mediaId, rootId = myDb.createMedia("name", "path", t)
        echo "todo"

    test "double transaction fail":
        myDb.beginTransaction
        try:
            myDb.beginTransaction
        except EMultiTransaction:
            nil
        
        finally:
            myDb.endTransaction(rollback = true)
            

  
