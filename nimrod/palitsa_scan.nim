import os

type
    TScanIface* = object
        onNewFile: proc()
        onEnterDir: proc()
        onLeaveDir: proc()


proc scanPath*(path: string, scanIface: TScanIface) =
    for k,p in path.walkDir:
        echo($k, " ", p)
    
    
var si: TScanIface
    
scanPath "./", si

