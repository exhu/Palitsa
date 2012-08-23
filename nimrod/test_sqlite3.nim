import db_sqlite

var
    mydb : TDbConn
    
mydb = db_sqlite.open("test.sqdb", "", "", "")


db_sqlite.close(mydb)
    
    
