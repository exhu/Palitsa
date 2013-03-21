# test dataset macro
import macros

import palitsa_sqlutils

template dataSet(body: stmt): stmt {.immediate.}=
    template col*(f: expr, t: typedesc, c: string): stmt {.immediate.}=
        echo "ok"
        echo(astToStr(f) & astToStr(t) & c)
        
    body
    
# ------------
dataSet:
    col id, TEntityId, "id"
    col name, string, "name"
    col originalPath, string, "original_path"
    col scanTime, TTime, "scan_time"
    col rootId, TEntityId, "root_id"
    
    
