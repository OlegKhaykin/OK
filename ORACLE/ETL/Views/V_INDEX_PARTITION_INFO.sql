CREATE OR REPLACE VIEW v_index_partition_info AS
SELECT
/*
  07-Dec-2021, OK: added IND_COLUMNS.
  17-Nov-2021, OK: new version
*/
  i.owner index_owner, i.index_name, i.index_type, 
  i.table_owner, i.table_name, i.uniqueness,
  TO_CHAR(concat_v2_set
  (
    CURSOR
    (
      SELECT column_name || DECODE(descend, 'DESC', 'DESC')
      FROM all_ind_columns
      WHERE index_owner = i.owner
      AND index_name = i.index_name
      ORDER BY column_position
    )
  )) ind_columns,
  i.status, i.pct_free, i.ini_trans, i.tablespace_name,
  pi.partitioning_type, pi.locality, pi.alignment,
  TO_CHAR(concat_v2_set
  (
    CURSOR
    (
      SELECT column_name 
      FROM all_part_key_columns
      WHERE owner = i.owner AND name = i.index_name
      ORDER BY column_position
    )
  )) AS partitioned_by,
  pi.subpartitioning_type,
  TO_CHAR(concat_v2_set
  (
    CURSOR
    (
      SELECT column_name 
      FROM all_subpart_key_columns
      WHERE owner = i.owner AND name = i.index_name
      ORDER BY column_position
    )
  )) AS sub_partitioned_by,
  p.partition_name,
  p.partition_position,
  p.high_value        AS part_high_value,
  p.status            AS part_status,
  p.composite,
  p.interval,
  p.blevel            AS part_blevel,
  p.num_rows          AS part_rows,
  p.distinct_keys     AS part_distinct_keys,
  p.clustering_factor AS part_clustering_factor,
  p.segment_created   AS part_segment_created,
  p.leaf_blocks       AS part_leaf_blocks,
  p.compression       AS part_compression,
  p.ini_trans         AS part_ini_trans,
  p.tablespace_name   AS part_tablespace,
  p.last_analyzed     AS part_last_analyzed,
  p.global_stats
FROM all_indexes i
LEFT JOIN all_part_indexes pi ON pi.owner = i.owner AND pi.index_name = i.index_name
LEFT JOIN TABLE(pkg_db_maintenance.get_index_partition_info(i.owner, i.index_name)) p ON 1=1;

GRANT SELECT ON v_index_partition_info TO csid, ods, dba;

BEGIN
  FOR r IN
  (
    SELECT role FROM dba_roles WHERE role = 'DEPLOYER'
  )
  LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON v_index_partition_info TO '||r.role;
  END LOOP;
END;
/