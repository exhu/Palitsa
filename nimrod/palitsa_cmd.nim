## command line tool for palitsa
import palitsa_db, palitsa_sqlutils, palitsa_db_scan
import os, times

proc initDb(o: var TOpenDb, args: openarray[string]): bool =
    echo "Initialzied."
    return true

proc enumMedia(o: var TOpenDb, args: openarray[string]): bool =
    # TODO
    if args.len != 2:
        echo "Expected name and path."
        return false


    #return true


proc addMedia(o: var TOpenDb, args: openarray[string]): bool =
    var (mediaId, rootId) = o.createMedia(args[0], args[1], getTime())
    o.addFsTree(rootId, args[1])
    return true
    


proc removeMedia(o: var TOpenDb, args: openarray[string]): bool =
    # TODO


proc mediaTree(o: var TOpenDb, args: openarray[string]):bool =
    # TODO
    # iterateDirEntryByParent
    
# -------

let
    commands = [("init", "create new db", initDb),
        ("amedia", "<name> <path> Add media from directory tree.", 
            addMedia),        
        ("lmedia", "List available media", enumMedia),
        ("media_tree", "<name> Dump tree", mediaTree),        
        ("remove_media", "<name> Deletes media", removeMedia),
    ]


# ------

proc displayHelp() =
    echo "Palitsa media catalog (C) 2012-2013 Yury Benesh"
    echo "palitsa_cmd <db_file> <command>"
    echo "Commands: "    
    for i in commands:
        echo i[0] & " - " & i[1]


# ------------------------------
# ---------- MAIN --------------
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
    var error = false
    for i in commands:
        if i[0] == cmd:
            found = true
            error = i[2](o, args)
            break
    if not found:
        displayHelp()
            
    o.closeDb()
    
# ------
main()