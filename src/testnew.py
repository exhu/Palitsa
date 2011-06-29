from palitsa.core.db_sqlite import DBSqLite
from palitsa.core.data import MediaDesc

import logging

logging.basicConfig(level=logging.DEBUG)


def test_new():
    db = DBSqLite("testdb1")
    db.create_new()
    db.close()


def test_open():
    db = DBSqLite("testdb1")
    print db.open()
    db.close()


def test_media_desc():
    db = DBSqLite("testdb1")
    print db.open()

    dao = db.get_media_desc_dao()

    mdesc = MediaDesc(name = "test pathname")
    dao.insert(mdesc)
    mdesc = dao.find(mdesc.id)
    print mdesc
    
    db.close()
    

test_new()
test_open()

test_media_desc()
