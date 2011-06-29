-- creates tables into a db
PRAGMA foreign_keys = ON;

-- system info table
CREATE TABLE db_desc (version_num INT, version_str TEXT);
INSERT INTO db_desc VALUES(101, "diskat 1.1");

-- media source info table
CREATE TABLE media_desc (id INTEGER PRIMARY KEY, name TEXT, original_path TEXT, scan_time INTEGER, root_id INTEGER, FOREIGN KEY(root_id) REFERENCES dir_entry_desc(id));

-- main table with directory entries, if parent_id is NULL then this is the root, look for media_desc with root_id = this.id
CREATE TABLE dir_entry_desc(id INTEGER PRIMARY KEY, parent_id INTEGER, dir_path TEXT, name TEXT, file_size INTEGER, mtime INTEGER, desc_id INTEGER,
    FOREIGN KEY(parent_id) REFERENCES dir_entry_desc(id),  FOREIGN KEY(desc_id) REFERENCES text_desc(id));

-- text descriptions table
CREATE TABLE text_desc (id INTEGER PRIMARY KEY, desc_text TEXT);

-- tags table
CREATE TABLE tag_desc (id INTEGER PRIMARY KEY, tag_name TEXT);

-- tags association with directory entries table
CREATE TABLE tag_dir_entry_assoc (id INTEGER PRIMARY KEY, tag_id INTEGER NOT NULL, dir_entry_id INTEGER NOT NULL, FOREIGN KEY(tag_id) REFERENCES tag_desc(id),
    FOREIGN KEY(dir_entry_id) REFERENCES dir_entry_desc(id), UNIQUE(tag_id, dir_entry_id));

-- indices to speed up search by tag_id or by dir_entry_id, e.g. we often need to show the tags attached to a certain directory entry, and vice versa
CREATE INDEX tag_dir_entry_assoc_tag_idx ON tag_dir_entry_assoc (tag_id);
CREATE INDEX tag_dir_entry_assoc_dir_idx ON tag_dir_entry_assoc (dir_entry_id);

-- index to speed up selection of child directory entries
CREATE INDEX dir_entry_desc_parent_idx ON dir_entry_desc (parent_id);

-- index to speed up search of directory entries by name
CREATE INDEX dir_entry_desc_name_idx ON dir_entry_desc (name);

