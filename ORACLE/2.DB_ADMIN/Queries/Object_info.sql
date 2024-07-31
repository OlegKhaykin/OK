ALTER SESSION SET nls_date_format = 'YYYY-MM-DD HH24:MI:SS'; 

-- Objects:
SELECT owner, object_name, object_type, status, created, last_ddl_time 
FROM dba_objects 
WHERE owner = 'OK'
ORDER BY object_type, object_name; 

-- Tables: 
SELECT t.owner, t.table_name, t.num_rows, t.blocks, NVL2(pt.table_name, 'Y', 'N') partitioned, t.last_analyzed 
FROM dba_tables t
LEFT JOIN dba_part_tables pt ON pt.owner = t.owner AND pt. table_name = t. table_name 
WHERE t.owner = 'OK' AND t.table_name LIKE 'DBG_%'
ORDER BY t.table_name; 

-- Columns:
SELECT * FROM v_column_info 
WHERE owner = 'OK' AND table_name LIKE 'DBG_%'
ORDER BY table_name, column_id; 

-- Indexes: 
SELECT * FROM v_all_indexes
WHERE table_owner = 'OK' AND table_name LIKE 'DBG_%'
ORDER BY table_owner, table_name, index_name; 

-- Views:
SELECT * FROM dba_views 
WHERE owner = 'OK' 
--AND view_name IN (WW_RISK SUBJECT_DIM')
; 

-- CLOBs:
SELECT * FROM dba_lobs 
WHERE owner = 'MADE SERVICES META' AND table_name = 'FAILED ODL MESSAGES'; 

-- Segments:
SELECT * FROM dba_segments
WHERE owner = 'MRDM SERVICES META' AND segment_type = 'LOBSEGMENT' 
AND segment_name IN ('SYS_LOB0000106593C00005W','SYS_LOB0000106593C00006W'); 

-- Extents:
SELECT * FROM dba_extents 
WHERE file_id = 200 AND block_id BETWEEN 88983 AND 88983+blocks; 

-- Changes: 
WITH
  tab_list AS
  (
    SELECT owner, table_name, last_analyzed, num_rows
    FROM dba_tables WHERE owner = 'OK'
  )
SELECT
  l.table_name, o.created, o.last_ddl_time, l.last_analyzed, 1.num_rows,
  m.partition_name, m.subpartition_name, m.inserts, m.updates, m.deletes, m.timestamp modification_ts,
  m.truncated, m.drop_segments
FROM tab_list l
JOIN dba_objects o ON o.object_name = l.table_name AND o.owner = l.owner AND o.object_type = 'TABLE'
LEFT JOIN dba_tab_modifications m ON m.table_name = l.table_name AND m.table_owner = l.owner
ORDER BY l.table_name, GREATEST(NVL(m.inserts,0), NVL(m.updates,0), NVL(m.deletes,0)) DESC; 
