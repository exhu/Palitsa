# --- database access interface ---
# -- version number 101 = 1.1
DB_VERSION_NUM = 101


class DBGeneric:
    def __init__(self, fn):
        self.filename = fn

    def create_new(self):
        return False

    def open(self):
        return False


    def close(self):
        pass


# -- DAOs
        
class MediaDescDAO:
    def insert(self, media_desc):
        """descendants return id number"""
        return None

    def find(self, media_desc_id):
        return None

    def remove(self, media_desc_id):
        """also must remove dependant tables, e.g. all direntries"""
        return False

    def update(self, media_desc):        
        return False

        
class DirEntryDescDAO:        
    def insert(self, dir_entry_desc):
        """descendants return id number"""
        return None

    def find(self, dir_entry_id):
        return None

    def remove(self, dir_entry_id):
        """also must remove dependant tables, e.g. children direntries, text descriptions..."""
        return False

        
class TextDescDAO:
    def insert(self, text_desc):
        """descendants return id number"""
        return None

    def find(self, text_desc_id):
        return None

    def remove(self, text_desc_id):
        """also must update dependant tables, e.g. direntries desc_id..."""
        return False
        

class TextDescDAO:
    def insert(self, text_desc):
        """descendants return id number"""
        return None

    def find(self, text_desc_id):
        return None

    def remove(self, text_desc_id):
        """also must update dependant tables, e.g. direntries desc_id..."""
        return False
        

class TagDescDAO:
    def insert(self, tag_desc):
        """descendants return id number"""
        return None

    def find(self, tag_desc_id):
        return None

    def remove(self, tag_desc_id):
        """also must update association table"""
        return False

    def attach(self, tag_id, dir_entry_id):
        """must create association entry in tag_dir_entry_assoc table"""
        return False
        
    def detach(self, tag_id, dir_entry_id):
        """must remove association entry in tag_dir_entry_assoc table"""
        return False

    def get_tags(self):
        """returns TagsBrowser"""
        return None

    def get_tags_for(self, dir_entry_id):
        """returns TagsBrowser"""
        return None


class TagsBrowser:
    """get next tag, get tag count etc."""

    """calculates maximum amount"""
    def get_count():
        return 0

    def reset():
        """Moves cursor to the first entry"""
        return False
    
    def get_next():
        """returns next TagDesc"""
        return None
        
