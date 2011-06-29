# --- sqlite implementation of db interface ---
from mediakat.core.db import DBGeneric
from mediakat.core.db import MediaDescDAO
from mediakat.core.data import MediaDesc

from mediakat.core.db import DB_VERSION_NUM

import sqlite3
import os
import logging

_logger = logging.getLogger('db_sqlite')

_DB_SCHEMA = "db_schema1.sql"

class DBSqLite(DBGeneric):
    def create_new(self):
        _logger.info(self.filename)
        _logger.info(_DB_SCHEMA)
        if os.path.exists(self.filename):
            os.remove(self.filename)

        if os.path.exists(_DB_SCHEMA):
            # import schema
            schema = file(_DB_SCHEMA).read()
        
            self.connection = sqlite3.connect(self.filename)

            cur = self.connection.cursor()

            
            cur.executescript(schema)

            self.connection.commit()
            
            cur.close()
        else:
            raise Exception("can't open schema " + _DB_SCHEMA)

        return True

    def open(self):
        self.connection = sqlite3.connect(self.filename)
        # check version
        cur = self.connection.cursor()
        cur.execute("select * from db_desc where version_num = ?", (DB_VERSION_NUM))
        ver = cur.fetchone()

        _logger.info(self.filename)
        _logger.info(ver)
        
        cur.close()        
        
        return ver is not None


    def close(self):
        
        self.connection.close()
        pass


    def get_media_desc_dao(self):
        return SQLiteMediaDescDAO(self)


#---------------------------

class SQLiteMediaDescDAO(MediaDescDAO):
    def __init__(self, dbo):
        self.dbo = dbo
    
    def insert(self, media_desc):
        """descendants return id number"""
        cur = self.dbo.connection.cursor()
        cur.execute('INSERT INTO media_desc (name, original_path, root_id) VALUES(?, ?, ?)', (media_desc.name, media_desc.original_path, media_desc.root_id))
        self.dbo.connection.commit()
        # last_insert_rowid()
        cur.execute('SELECT id FROM media_desc WHERE id = last_insert_rowid()')
        media_desc.id = cur.fetchone()[0]

        cur.close()
        return media_desc.id

    def find(self, media_desc_id):        
        cur = self.dbo.connection.cursor()
        cur.execute('SELECT id, name, original_path, root_id FROM media_desc WHERE id = 1')#, (media_desc_id))        
        res = cur.fetchone()
        md = None
        if res is not None:
            md = MediaDesc(e_id = res[0], name = res[1], original_path = res[2], root_id = res[3])        

        cur.close()        
        return md

    def remove(self, media_desc_id):
        """also must remove dependant tables, e.g. all direntries"""

        # TODO
        return False
