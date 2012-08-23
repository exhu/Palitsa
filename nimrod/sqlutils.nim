import strutils


type
    TStatements* = seq[string]

    TSqlParser = ref object
        statements : TStatements
        curStatement: string

proc parseLine(p : TSQLParser, s : string) =
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
            else:
                possibleComments = true
                continue
        else:
            if possibleComments:
                possibleComments = false
                p.curStatement &= "-"
                
        p.curStatement &= $i

            
    
        
proc ParseSqlFile*(fn : string) : TStatements =
     var p : TSqlParser
     new(p)
     
     
     
# ------------------
        
when isMainModule:
    # test
    #var tparser =
    
