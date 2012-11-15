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
            check BiggestInt(id1) > 0
            var id2 = myDb.genIdFor(ptMediaDesc)
            check BiggestInt(id2) > 1
            
    test "genId fail rollback":
        var idBeforeFail: TEntityId
        inTransaction(myDb, rollback = true):
            idBeforeFail = myDb.genIdFor(ptMediaDesc)
        inTransaction(myDb, rollback = true):
            var id = myDb.genIdFor(ptMediaDesc)
            check BiggestInt(id) == BiggestInt(idBeforeFail)



# TODO test id generation

# var a: TOpenDb
# 
# a.openDb("ttt.db", recreate = true)
# a.closeDb()
  
