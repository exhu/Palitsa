## command line tool for palitsa
import palitsa_db, palitsa_sqlutils, palitsa_db_scan
import os, times

proc initDb(o: var TOpenDb, args: openarray[string]): bool =
    echo "Initialzied."
    return true

proc enumMedia(o: var TOpenDb, args: openarray[string]): bool =
    for i in o.iterateMedia():
        echo($i.id & "\t" & $i.name & "\t" & $i.originalPath)

    return true


proc addMedia(o: var TOpenDb, args: openarray[string]): bool =
    if args.len != 2:
        echo "Expected name and path."
        return false

    var (mediaId, rootId) = o.createMedia(args[0], args[1], getTime())
    o.addFsTree(rootId, args[1])
    echo "Finished."
    return true
    


proc removeMedia(o: var TOpenDb, args: openarray[string]): bool =
    # TODO


proc dumpTree(o: var TOpenDb, parent: TEntityId, level: int) =
    var ident = ""
    for i in countup(0, level):
        ident &= "| "

    for i in o.iterateDirEntryByParent(parent):
        echo(ident, i.name)
        if i.isDir:
            o.dumpTree(i.id, level+1)


proc mediaTree(o: var TOpenDb, args: openarray[string]):bool =
    var m: TMediaDesc
    if o.findMediaByName(args[0], m):
        o.dumpTree(m.rootId, 0)
        return true

    echo "No media '" & args[0] & "' found."
    return false
    
    
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
        for i in countup(3, paramCount()):            
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
