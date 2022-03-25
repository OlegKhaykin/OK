CREATE OR REPLACE VIEW v_table_partition_info AS
SELECT
  -- 2022-02-09, OK: added more columns and switched to PKG_DB_MAINTENANCE_API.
  -- 2021-12-26, OK: changed expression for TABLESPACE_NAME.
  -- 2021-11-18, OK: used ALL_TABLES, added (SUB)PART_INI_TRANS and (SUB)PART_PCT_FREE.
  -- 2019-12-11, OK: added column SUB_PARTITIONED_BY
  inf.owner, inf.table_name,
  inf.partitioning_type, inf.partitioned_by, inf.part_key_column_cnt, inf.interval,
  inf.subpartitioning_type, inf.subpartitioned_by, inf.subpart_key_column_cnt, inf.interval_subpartition,
  COALESCE(sp.compress_for, p.compress_for, inf.compress_for) compression,
  COALESCE(sp.pct_free, p.pct_free, inf.pct_free) pct_free, 
  COALESCE(sp.ini_trans, p.ini_trans, inf.ini_trans) ini_trans,
  COALESCE(sp.tablespace_name, p.tablespace_name, inf.tablespace_name) tablespace_name,
  COALESCE(sp.segment_created, p.segment_created, inf.segment_created) segment_created,
  inf.table_last_analyzed, inf.table_rows, inf.table_blocks,
  --
  p.partition_name,
  p.partition_position,
  p.high_value              AS part_high_value,
  p.last_analyzed           AS part_last_analyzed,
  p.num_rows                AS part_rows,
  p.blocks                  AS part_blocks,
  --
  sp.subpartition_name, 
  sp.subpartition_position, 
  sp.high_value             AS subpart_high_value,
  sp.last_analyzed          AS subpart_last_analyzed,
  sp.num_rows               AS subpart_rows, 
  sp.blocks                 AS subpart_blocks
FROM
(
  SELECT
    t.owner, t.table_name, t.compress_for, t.pct_free, t.ini_trans,
    t.tablespace_name, t.segment_created,
    t.last_analyzed table_last_analyzed, t.num_rows table_rows, t.blocks table_blocks,
    pt.partitioning_type, pt.interval,
    (
      SELECT LISTAGG(column_name, ',') WITHIN GROUP(ORDER BY column_position) 
      FROM all_part_key_columns
      WHERE owner = t.owner AND name = t.table_name
    ) AS partitioned_by,
    (
      SELECT COUNT(1) 
      FROM all_part_key_columns
      WHERE owner = t.owner AND name = t.table_name
    ) AS part_key_column_cnt,
    pt.subpartitioning_type, pt.interval_subpartition,
    (
      SELECT LISTAGG(column_name, ',') WITHIN GROUP(ORDER BY column_position)
      FROM all_subpart_key_columns
      WHERE owner = t.owner AND name = t.table_name
    ) AS subpartitioned_by,
    (
      SELECT COUNT(1)
      FROM all_subpart_key_columns
      WHERE owner = t.owner AND name = t.table_name
    ) AS subpart_key_column_cnt
  FROM all_tables t
  LEFT JOIN all_part_tables pt ON pt.owner = t.owner AND pt.table_name = t.table_name
) inf
LEFT JOIN TABLE(pkg_db_maintenance_api.get_partition_info(inf.owner, inf.table_name)) p ON 1=1
LEFT JOIN TABLE(pkg_db_maintenance_api.get_subpartition_info(inf.owner, inf.table_name, p.partition_name)) sp ON 1=1;

GRANT READ ON v_table_partition_info TO PUBLIC;