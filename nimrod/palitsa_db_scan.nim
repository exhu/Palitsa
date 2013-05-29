import os
import palitsa_db, palitsa_scan

# this module scans dirs and populates db

proc addTree(parent: TEntityId, path: string) =
## Scans filesystem and adds files/directories to specified 
## 'parent' TDirEntryDesc which is usually a generated root_id received
## from createMedia().
    echo "addTree"
    

