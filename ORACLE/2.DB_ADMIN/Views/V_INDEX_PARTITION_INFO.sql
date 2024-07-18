CREATE OR REPLACE VIEW v_index_partition_info AS
SELECT
/*
  22-Mar-2022, OK: bug fix in DECODE in the IND_COLUMNS sub-query.
  08-Feb-2022, OK: added more columns, switched to PKG_DB_MAINTENANCE_API.
  07-Dec-2021, OK: added column IND_COLUMNS.
  17-Nov-2021, OK: new version
*/
  inf.index_owner, inf.index_name, inf.generated, inf.index_type,
  inf.table_owner, inf.table_name, inf.uniqueness, inf.visibility,
  inf.ind_columns, inf.ind_col_cnt, inf.status,
  inf.constraint_name, inf.constraint_type, inf.partitioning_type, inf.locality, inf.alignment,
  COALESCE(sp.compression, p.compression, inf.compression) compression,
  COALESCE(sp.pct_free, p.pct_free, inf.pct_free) pct_free, 
  COALESCE(sp.ini_trans, p.ini_trans, inf.ini_trans) ini_trans,
  COALESCE(sp.tablespace_name, p.tablespace_name, inf.tablespace_name) tablespace_name,
  COALESCE(sp.segment_created, p.segment_created, inf.segment_created) segment_created,
  inf.last_analyzed, inf.num_rows, inf.leaf_blocks,
  --
  p.partition_name,
  p.partition_position,
  p.high_value              AS part_high_value,
  p.interval                AS part_interval,
  p.composite               AS part_composite,
  p.status                  AS part_status,
  p.last_analyzed           AS part_last_analyzed,
  p.global_stats            AS part_global_stats,
  p.num_rows                AS part_rows,
  p.leaf_blocks             AS part_leaf_blocks,
  p.distinct_keys           AS part_distinct_keys,
  p.clustering_factor       AS part_clustering_factor,
  p.blevel                  AS part_blevel,
  --
  sp.subpartition_name,
  sp.subpartition_position,
  sp.high_value             AS subpart_high_value,
  sp.interval               AS subpart_interval,
  sp.status                 AS subpart_status,
  sp.last_analyzed          AS subpart_last_analyzed,
  sp.global_stats           AS subpart_global_stats,
  sp.num_rows               AS subpart_rows,
  sp.leaf_blocks            AS subpart_leaf_blocks,
  sp.distinct_keys          AS subpart_sistinct_keys,
  sp.clustering_factor      AS subpart_clustering_factor,
  sp.blevel                 AS subpart_blevel
FROM
(
  SELECT --+ NO_UNNEST
    i.owner index_owner, i.index_name, i.generated, i.index_type, 
    i.table_owner, i.table_name, i.uniqueness, i.compression, i.visibility,
    i.status, i.pct_free, i.ini_trans, i.tablespace_name, i.segment_created,
    i.last_analyzed, i.num_rows, i.leaf_blocks,
    c.constraint_name, c.constraint_type,
    (
      SELECT LISTAGG(column_name||DECODE(descend, 'DESC', ' DESC'), ',') WITHIN GROUP(ORDER BY column_position)
      FROM all_ind_columns
      WHERE index_owner = i.owner
      AND index_name = i.index_name
    ) ind_columns,
    (
      SELECT COUNT(1)
      FROM all_ind_columns
      WHERE index_owner = i.owner AND index_name = i.index_name
    ) ind_col_cnt,
    pi.partitioning_type, pi.locality, pi.alignment,
    (
      SELECT LISTAGG(column_name, ',') WITHIN GROUP(ORDER BY column_position)
      FROM all_part_key_columns
      WHERE owner = i.owner AND name = i.index_name
    ) AS partitioned_by,
    pi.subpartitioning_type,
    (
      SELECT LISTAGG(column_name, ',') WITHIN GROUP(ORDER BY column_position) 
      FROM all_subpart_key_columns
      WHERE owner = i.owner AND name = i.index_name
    ) AS sub_partitioned_by
  FROM all_indexes i
  LEFT JOIN all_constraints c
    ON c.owner = i.owner AND c.index_name = i.index_name 
  LEFT JOIN all_part_indexes pi ON pi.owner = i.owner AND pi.index_name = i.index_name
) inf
LEFT JOIN TABLE(pkg_db_maintenance_api.get_index_partition_info(inf.index_owner, inf.index_name)) p ON 1=1
LEFT JOIN TABLE(pkg_db_maintenance_api.get_index_subpartition_info(inf.index_owner, inf.index_name, p.partition_name)) sp ON 1=1;

GRANT READ ON v_index_partition_info TO PUBLIC;
