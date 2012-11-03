import os
import times

var path = paramStr(1)

# dir scanning
proc myWalk(path: string) =
    for k,p in walkDir(path):
        echo k.repr & " " & p
        if k == pcDir:
            myWalk(p)
  
myWalk(path)
echo getGMTime(getTime())

discard stdIn.readLine()
