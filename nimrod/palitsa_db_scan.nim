## this module scans dirs and populates db

import os
import palitsa_db, palitsa_scan, palitsa_sqlutils


proc addEntry(o: ptr TOpenDb, curDir: TEntityId, fn: string, 
    isDir: bool): TEntityId =

    var e: TDirEntryDesc
    e.parentId = curDir
    let (dir, name, ext) = fn.splitFile
    e.path = dir
    e.name = name & ext
    e.fileSize = fn.getFileSize()
    e.mTime = fn.getLastModificationTime()
    e.isDir = isDir
    
    o[].createEntry(e)


proc addFsTree*(o: var TOpenDb, parent: TEntityId, path: string) =
    ## Scans filesystem and adds files/directories to specified 
    ## 'parent' TDirEntryDesc which is usually a generated root_id received
    ## from createMedia().
    echo "addTree"
    var 
        sif: TScanIface
        curDir = parent
        dirStack: seq[TEntityId] = @[]
        
    let pO = addr(o) # some hack -) i know the o will be alive in the following
    # closures and we cannot pass it as var, so let's pass it as ptr...
        
    sif.onNewFile = proc(fn:string) =        
        discard addEntry(pO, curDir, fn, isDir = false)
        
    sif.onEnterDir = proc(fn:string) =
        dirStack.add(curDir)
        curDir = addEntry(pO, curDir, fn, isDir = true)        
        
    sif.onLeaveDir = proc(fn:string) =        
        curDir = dirStack.pop()

    inTransaction(o):
        scanPath(path, sif)
    

# TODO write unit test

