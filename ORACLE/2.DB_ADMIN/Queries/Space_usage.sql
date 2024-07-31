with
  space as
  (
    select
    tablespace name, round (sum(user_bytes)/107374182¢) gb
    from dba_data_files
    --where tablespace name not in (*DBA_AUDIT','SYSTEM','SYSAUX','UNDOTBSL','UNDOTBS2')
    group by rollup (tablespace name)
  )
  , segm as
  (
    select owner, segment name, tablespace name, round (sum(bytes)/104357¢) mb
    from dba_segments ©
    where tablespace name not in ('DBA_AUDIT','SYSTEM','SYSAUX','UNDOTBSL','UNDOTBS2')
    group by owner, segment name, tablespace name
  )
  , used as
  (
    select tablespace name, round (sum(mb)/1024) gb
    from seam
    --wnere tablespace name not in ('DBA_AUDIT','SYSTEM','SYSAUX','UNDOTBSL','UNDOTBS2')
    group by tablespace name
  )
  , free space as
  (
    select tablespace name, round (smm(bytes)/1073741524) gb
    from dba_free_space
    where tablespace name not in ('DBA_AUDIT','SYSTEM','SYSAUX','UNDOTBSL','UNDOTBS2')
    group by tablespace name
  )
--select * from free space
--select * from all space;
select a.tablespace name, a.gb total gb, u.gb used gb, f.ob free gb, round(f.gb/a.gb¥l00) free pet
from all_space a
left join used u on u.tablespace name = a.tablespace name
left join free space f on f.tablespace name = a.tablespace name
order by 1;

-- Segment size totals by schemas/tablespaces: select * from 
SELECT * FROM
(
  SELECT
    --owner, 
    segment_type,
    tablespace_name, 
    ROUND(SUM(bytes)/1048576) MB
  FROM dba_segments
  WHERE tablespace_name IN ('SYSTEM','SYSAUX','USERS')
  GROUP BY tablespace_name, segment_type
)
PIVOT(SUM(mb) FOR tablespace_name IN ('SYSTEM','SYSAUX','USERS'))
ORDER BY segment_type; 

-- Table sizes - with indexes and LOBs:
WITH
  det AS 
  (
    SELECT
      COALESCE(l.table_name, i.table_name, s.segment_name) table_name,
      CASE WHEN s.segment_type LIKE '%TABLE%' THEN s.blocks END data_blocks,
      CASE WHEN s.segment_type LIKE '%INDEX%' THEN s.blocks END index_blocks,
      CASE WHEN s.segment_type LIKE '%LOB%'   THEN s.blocks END lob_blocks
    FROM dba_segments s
    LEFT JOIN dba_indexes i ON i.owner = s.owner AND i.index_name = s.segment_name AND s.segment_type LIKE '%INDEX'
    LEFT JOIN dba_lobs l ON l.owner = s.owner AND l.segment_name = s.segment_name AND s.segment_type LIKE '%LOB'
    --WHERE s.owner = 'MRDM'
  ),
  tot as
  (
    SELECT
      table_name,
      ROUND(SUM(data_blocks)/128)  data_mb,
      ROUND(SUM(index_blocks)/128) index_mb,
      ROUND(SUM(lob_blocks)/128) lob_mb
    FROM det
    GROUP BY table_name
  )
SELECT t.*, NVL(data_mb, 0) + NVL(index_mb, 0) + NVL(lob_mb, 0) total_mb
FROM tot t
ORDER BY total_mb DESC NULLS LAST; 

 -- TEMP space: 
 SELECT
   tablespace_name,
   block_size,
   max_size max_blocks,
   ROUND(max_size * block_size/1073741824) max_gb
FROM dba_tablespaces
--from cdb_tablespaces
WHERE contents = 'TEMPORARY';

SELECT
  --con_id, 
  tablespace_name, ROUND(SUM(bytes)/1048576) mb
FROM dba_temp_files
--from odb_temp_files
WHERE tablespace_name = 'TEMP'
GROUP BY tablespace_name;

WITH
  FUNCTION to_mb_str(p_in INTEGER) RETURN VARCHAR2 AS
  BEGIN
    RETURN TO_CHAR(p_in/1048576, '9,999,990.9')||' MB'; 
  END;
SELECT
  f. tablespace_name, 
  to_mb_str(f.tablespace_size) tablespace_size,
  to_mb_str(f.free_space) free_space,
  to_mb_str(f.allocated_space) allocated_space,
  to_mb_str(f.tablespace_size - f.free_space) used_space,
  ROUND(f.free_space/f.tablespace_size*100) free_pct 
FROM dba_temp_free_space f; 
/

select * from dba_datafiles; 
select * from gvSdatafile; 
select * from gv$tempfile; 
select * from v$controlfile;
select * from v$logfile; 
