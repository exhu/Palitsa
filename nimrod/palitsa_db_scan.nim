import os
import palitsa_db, palitsa_scan

# this module scans dirs and populates db

proc addTree*(parent: TEntityId, path: string) =
## Scans filesystem and adds files/directories to specified 
## 'parent' TDirEntryDesc which is usually a generated root_id received
## from createMedia().
    echo "addTree"
    var 
        sif: TScanIface
        curDir = parent
        dirStack: seq[TEntityId] = @[]
        
    sif.onNewFile = proc(fn:string) =
        echo "TODO add file"
        
    sif.onEnterDir = proc(fn:string) =
        dirStack.push(curDir)
        # TODO create entity for dir, set curDir
        
    sif.onLeaveDir = proc(fn:string) =
        echo "TODO pop curDir"
        curDir = dirStack.pop()

    scanPath(path, sif)
    

