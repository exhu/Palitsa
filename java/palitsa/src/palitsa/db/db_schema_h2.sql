-- creates tables into a db

-- system info table
CREATE TABLE db_desc (version_num INT, version_str TEXT, notes TEXT);
INSERT INTO db_desc VALUES(102, "palitsa 1.2 h2", "java h2");

-- ids generator
CREATE TABLE id_seq (table_name VARCHAR(60) PRIMARY KEY, nextv BIGINT);
INSERT INTO id_seq VALUES("media_desc", 1);
INSERT INTO id_seq VALUES("dir_entry_desc", 1);
INSERT INTO id_seq VALUES("text_desc", 1);
INSERT INTO id_seq VALUES("tag_desc", 1);
INSERT INTO id_seq VALUES("tag_dir_entry_assoc", 1);


-- media source info table
CREATE TABLE media_desc (id BIGINT PRIMARY KEY, 
	name TEXT, original_path TEXT, scan_time TIMESTAMP, root_id BIGINT, 
	FOREIGN KEY(root_id) REFERENCES dir_entry_desc(id));

-- main table with directory entries, if parent_id is NULL then this is the root, look for media_desc with root_id = this.id
CREATE TABLE dir_entry_desc(id BIGINT PRIMARY KEY, parent_id BIGINT, 
	dir_path TEXT, name TEXT, file_size BIGINT, mtime INTEGER, 
	desc_id BIGINT,
    FOREIGN KEY(parent_id) REFERENCES dir_entry_desc(id),  FOREIGN KEY(desc_id) REFERENCES text_desc(id));

-- text descriptions table
CREATE TABLE text_desc (id BIGINT PRIMARY KEY, desc_text TEXT);

-- tags table
CREATE TABLE tag_desc (id BIGINT PRIMARY KEY, tag_name TEXT);

-- tags association with directory entries table
CREATE TABLE tag_dir_entry_assoc (id BIGINT PRIMARY KEY, tag_id BIGINT NOT NULL, dir_entry_id BIGINT NOT NULL, FOREIGN KEY(tag_id) REFERENCES tag_desc(id),
    FOREIGN KEY(dir_entry_id) REFERENCES dir_entry_desc(id), UNIQUE(tag_id, dir_entry_id));

-- indices to speed up search by tag_id or by dir_entry_id, e.g. we often need to show the tags attached to a certain directory entry, and vice versa
CREATE INDEX tag_dir_entry_assoc_tag_idx ON tag_dir_entry_assoc (tag_id);
CREATE INDEX tag_dir_entry_assoc_dir_idx ON tag_dir_entry_assoc (dir_entry_id);

-- index to speed up selection of child directory entries
CREATE INDEX dir_entry_desc_parent_idx ON dir_entry_desc (parent_id);

-- index to speed up search of directory entries by name
CREATE INDEX dir_entry_desc_name_idx ON dir_entry_desc (name);

