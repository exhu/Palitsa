import os
import palitsa_db

type
    TScanIface* = object
        onNewFile*: proc(fn: string) ## fn = full file name with path
        onEnterDir*: proc(fn: string)
        onLeaveDir*: proc(fn: string)


proc scanPath*(path: string, scanIface: TScanIface) =
    for k,p in path.walkDir:
        #echo($k, " ", p)
        case k
        of pcFile:
            scanIface.onNewFile(p)
        of pcDir:
            scanIface.onEnterDir(p)
            scanPath(p, scanIface)
            scanIface.onLeaveDir(p)
        else:
            # not supported
            discard
        
            
    
discard """    
var si: TScanIface
    
si.onNewFile = proc(fn: string) = 
    echo("new file = " & fn)
si.onEnterDir = proc(fn: string) =
    echo("entering dir = " & fn)
    
si.onLeaveDir = proc(fn: string) =
    echo("leaving dir = " & fn)
    
scanPath "./", si
"""

