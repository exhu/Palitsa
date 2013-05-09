type
    TScanIface* = object
        onNewFile: proc()
        onEnterDir: proc()
        onLeaveDir: proc()


proc scanPath*(path: string, scanIface: TScanIface) =
    nil
