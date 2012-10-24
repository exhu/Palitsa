import db_sqlite
import os

import sqlutils

var
  mydb : TDbConn
    
let dbFile = "test.sqdb"
let dbScript = "db_schema1_sqlite.sql"

removeFile dbFile
mydb = db_sqlite.open(dbFile, "", "", "")
let script = parseSqlFile(dbScript)
for i in script:
  echo "executing '" & i & "'..."
  db_sqlite.exec mydb, TSqlQuery(i)

db_sqlite.close(mydb)
    
discard stdin.readLine()

    
