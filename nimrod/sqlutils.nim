import strutils


type
    TStatements* = seq[string]

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
     
# ------------------
        
when isMainModule:
  var st : TStatements

  st = ParseSqlFile("db_schema1_sqlite.sql")

  for s in items(st):
    echo s
  