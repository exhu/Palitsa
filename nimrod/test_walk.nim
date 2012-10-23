import os
import times

var path = paramStr(1)

# dir scanning

for k,p in walkDir(path):
  echo k.repr & " " & p
  
echo getGMTime(getTime())

