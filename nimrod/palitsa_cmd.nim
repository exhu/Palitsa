## command line tool for palitsa
import palitsa_db, palitsa_sqlutils
import os

proc initDb(o: var TOpenDb, args: openarray[string]) =
    echo "Initialzied."

proc enumMedia(o: var TOpenDb, args: openarray[string]) =
    # TODO

proc enumDirTreeForMedia(o: var TOpenDb, mediaId: TEntityId) =
    # TODO
    # iterateDirEntryByParent
    

let
    commands = [("init", "create new db", initDb), 
        ("lmedia", "List media", enumMedia)]
    
proc displayHelp() =
    echo "Palitsa media catalog (C) 2012-2013 Yury Benesh"
    echo "palitsa_cmd <db_file> <command>"
    echo "Commands: "    
    for i in commands:
        echo i[0] & " - " & i[1]


proc main() =    
    if paramCount() < 2:
        displayHelp()
        return
    
    var o: TOpenDb
    let cmd = paramStr(2)
    var args:seq[string] = @[]
    if paramCount() > 2:
        for i in countup(3, paramCount()-1):            
            args.add(paramStr(i))
        
    o.openDb(paramStr(1), recreate = (paramStr(2) == "init"))
    var found = false
    for i in commands:
        if i[0] == cmd:
            found = true
            i[2](o, args)
            break
    if not found:
        displayHelp()
            
    o.closeDb()
    
# ------
main()
