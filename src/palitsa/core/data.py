# --- data structures ---

class DBDesc:
    def __init__(self):
        self.version_num = 1
        self.version_str = "palitsa 1.0"


class MediaDesc:
    def __init__(self, e_id = None, name = None, original_path = None, root_id = None):
        self.id = e_id
        self.name = name
        self.original_path = original_path
        self.root_id = root_id

    def __str__(self):
        res = ""
        for i in dir(self):
            res = ", ".join((res, " = ".join((i, str(getattr(self, i))))))

        return res
        #return "id, name, original_path, root_id = " + ", ".join((self.id, self.name, self.original_path, self.root_id))

    
class DirEntryDesc:
    def __init__(self, e_id = None, parent_id = None, dir_path = None, name = None, file_size = None, mtime = None, desc_id = None):
        self.id = e_id
        self.parent_id = parent_id
        self.dir_path = dir_path
        self.name = name
        self.file_size = file_size
        self.mtime = mtime
        self.desc_id = desc_id


class TextDesc:
    def __init__(self, e_id = None, desc_text = None):
        self.id = e_id
        self.desc_text = None

        
class TagDesc:
    def __init__(self, e_id = None, tag_name = None):
        self.id = e_id
        self.tag_name = tag_name


