CREATE OR REPLACE VIEW v_table_partition_info AS
SELECT
  -- 2021-12-26, OK: changed expression for TABLESPACE_NAME.
  -- 2021-11-18, OK: used ALL_TABLES, added (SUB)PART_INI_TRANS and (SUB)PART_PCT_FREE. 
  -- 2019-12-11, OK: added column SUB_PARTITIONED_BY
  t.owner, t.table_name, t.compress_for table_compression, t.pct_free table_pct_free, t.ini_trans table_ini_trans, t.num_rows table_rows, t.blocks table_blocks,
  TO_CHAR(concat_v2_set
  (
    CURSOR
    (
      SELECT column_name 
      FROM all_part_key_columns
      WHERE owner = t.owner AND name = t.table_name
      ORDER BY column_position
    )
  )) AS partitioned_by,
  TO_CHAR(concat_v2_set
  (
    CURSOR
    (
      SELECT column_name 
      FROM all_subpart_key_columns
      WHERE owner = t.owner AND name = t.table_name
      ORDER BY column_position
    )
  )) AS sub_partitioned_by,
  p.partition_name, p.partition_position, p.high_value,
  COALESCE(sp.tablespace_name, p.tablespace_name, t.tablespace_name) AS tablespace_name,
  p.compress_for part_compression, p.ini_trans part_ini_trans, p.pct_free part_pct_free, p.num_blocks part_blocks,
  p.num_rows part_rows, p.last_analyzed part_last_analyzed,
  sp.subpartition_name, sp.subpartition_position, sp.high_value subpart_high_value,
  sp.compress_for subpart_compression, sp.ini_trans subpart_ini_trans, sp.pct_free subpart_pct_free, sp.num_blocks subpart_blocks,
  sp.num_rows subpart_rows, sp.last_analyzed subpart_last_analyzed
FROM all_tables t
LEFT JOIN all_part_tables pt ON pt.owner = t.owner AND pt.table_name = t.table_name
LEFT JOIN TABLE(pkg_db_maintenance.get_partition_info(t.owner, t.table_name)) p ON 1=1
LEFT JOIN TABLE(pkg_db_maintenance.get_subpartition_info(t.owner, t.table_name)) sp ON sp.partition_name = p.partition_name;

GRANT SELECT ON etladmin.v_table_partition_info TO csid, ods;