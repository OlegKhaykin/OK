CREATE OR REPLACE PACKAGE BODY pkg_db_info AS
/*
  History of changes (newest to oldest):
  -----------------------------------------------------------------
  18-JUL-2024, Oleg Khaykin (OK): created
*/
  -- This pipelined table function returns information about table partitions
  FUNCTION get_partition_info
  (
    p_table_owner           IN VARCHAR2,
    p_table_name            IN VARCHAR2,
    p_partition_name        IN VARCHAR2 DEFAULT NULL,
    p_partition_position    IN NUMBER DEFAULT NULL
  ) RETURN tab_partition_info PIPELINED IS
    rec rec_partition_info;
  BEGIN
    FOR r IN
    (
      SELECT
        table_owner, table_name,
        partition_name, partition_position, high_value, interval, composite, indexing,
        subpartition_count, compress_for, ini_trans, pct_free,
        tablespace_name, segment_created, last_analyzed, blocks, num_rows,
        DECODE (inmemory, 'ENABLED', inmemory_priority, 'N/A') inmemory_priority,
        DECODE (inmemory, 'ENABLED', inmemory_distribute, 'N/A') inmemory_distribute,
        DECODE (inmemory, 'ENABLED', inmemory_compression, 'N/A') inmemory_compression
      FROM all_tab_partitions
      WHERE table_owner = p_table_owner AND table_name = p_table_name
      AND partition_name = NVL(p_partition_name, partition_name)
      AND partition_position = NVL(p_partition_position, partition_position)
    )
    LOOP
      rec.table_owner := r.table_owner;
      rec.table_name := r.table_name;
      rec.partition_name := r.partition_name;
      rec.partition_position := r.partition_position;
      rec.high_value := r.high_value; -- LONG -> VARCHAR2
      rec.interval := r.interval;
      rec.indexing := r.indexing;
      rec.composite := r.composite;
      rec.subpartition_count := r.subpartition_count;
      rec.compress_for := r.compress_for;
      rec.ini_trans := r.ini_trans;
      rec.pct_free := r.pct_free;
      rec.tablespace_name := r.tablespace_name;
      rec.segment_created := r.segment_created;
      rec.last_analyzed := r.last_analyzed;
      rec.num_rows := r.num_rows;
      rec.blocks := r.blocks;
      rec.inmemory_priority := r.inmemory_priority;
      rec.inmemory_distribute := r.inmemory_distribute;
      rec.inmemory_compression := r.inmemory_compression;

      PIPE ROW(rec);
    END LOOP;
  END get_partition_info;
  
  
  -- This pipelined table function returns information about table subpartitions
  FUNCTION get_subpartition_info
  (
    p_table_owner     IN VARCHAR2,
    p_table_name      IN VARCHAR2,
    p_partition_name  IN VARCHAR2 DEFAULT NULL
  ) RETURN tab_subpartition_info PIPELINED IS
    rec rec_subpartition_info;
  BEGIN
    FOR r IN
    (
      SELECT
        table_owner, table_name, partition_name,
        subpartition_name, subpartition_position, high_value, interval,
        compress_for, ini_trans, pct_free, tablespace_name, segment_created,
        last_analyzed, num_rows, blocks,
        DECODE (inmemory, 'ENABLED', inmemory_priority, 'N/A') inmemory_priority,
        DECODE (inmemory, 'ENABLED', inmemory_distribute, 'N/A') inmemory_distribute,
        DECODE (inmemory, 'ENABLED', inmemory_compression, 'N/A') inmemory_compression
      FROM all_tab_subpartitions
      WHERE table_owner = p_table_owner AND table_name = p_table_name
      AND partition_name = NVL(p_partition_name, partition_name)
    )
    LOOP
      rec.table_owner := r.table_owner;
      rec.table_name := r.table_name;
      rec.partition_name := r.partition_name;
      rec. subpartition_name := r.subpartition_name;
      rec.subpartition_position := r.subpartition_position;
      rec.high_value := r.high_value; -- LONG -> VARCHAR2
      rec.interval := r.interval;
      rec.compress_for := r.compress_for;
      rec.ini_trans := r.ini_trans;
      rec.pct_free := r.pct_free;
      rec.tablespace_name := r.tablespace_name;
      rec.segment_created := r.segment_created;
      rec.last_analyzed := r.last_analyzed;
      rec.num_rows := r.num_rows;
      rec.blocks := r.blocks;
      rec.inmemory_priority := r.inmemory_priority;
      rec.inmemory_distribute := r.inmemory_distribute;
      rec.inmemory_compression := r.inmemory_compression;

      PIPE ROW(rec) ;
    END LOOP;
  END get_subpartition_info;
  
  
  -- This pipelined table function returns information about index partitions
  FUNCTION get_index_partition_info
  (
    p_index_owner         IN VARCHAR2,
    p_index_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL,
    p_partition_position  IN NUMBER DEFAULT NULL
  ) RETURN tab_index_partition_info PIPELINED IS
    rec rec_index_partition_info;
  BEGIN
    FOR r IN
    (
      SELECT
        index_owner, index_name, partition_name, partition_position, high_value, interval, composite,
        tablespace_name, segment_created, status, compression, pct_free, ini_trans,
        last_analyzed, global_stats, num_rows, leaf_blocks, distinct_keys, clustering_factor, blevel
      FROM all_ind_partitions
      WHERE index_owner = p_index_owner AND index_name = p_index_name
      AND partition_name = NVL(p_partition_name, partition_name)
      AND partition_position = NVL(p_partition_position, partition_position)
    )
    LOOP
      rec.index_owner := r.index_owner;
      rec.index_name := r.index_name;
      rec.partition_name := r.partition_name;
      rec.partition_position := r.partition_position;
      rec.high_value := r.high_value; -- LONG -> VARCHAR2
      rec.interval := r.interval;
      rec.composite := r.composite;
      rec.compression := r.compression;
      rec.pct_free := r.pct_free;
      rec.ini_trans := r.ini_trans;
      rec.tablespace_name := r.tablespace_name;
      rec.segment_created := r.segment_created;
      rec.status := r.status;
      rec.last_analyzed := r.last_analyzed;
      rec.global_stats := r.global_stats;
      rec.num_rows := r.num_rows;
      rec.leaf_blocks := r.leaf_blocks;
      rec.distinct_keys := r.distinct_keys;
      rec.clustering_factor := r.clustering_factor;
      rec.blevel := r.blevel;

      PIPE ROW(rec) ;
    END LOOP;

    RETURN;
  END get_index_partition_info;
  
  
  -- This pipelined table function returns information about index subpartitions
  FUNCTION get_index_subpartition_info
  (
    p_index_owner       IN VARCHAR2,
    p_index_name        IN VARCHAR2,
    p_partition_name    IN VARCHAR2 DEFAULT NULL
  ) RETURN tab_index_subpartition_info PIPELINED IS
    rec rec_index_subpartition_info;
  BEGIN
    FOR r IN
    (
      SELECT
        index_owner, index_name, partition_name,
        subpartition_name, subpartition_position,
        high_value, interval, compression, pct_free, ini_trans,
        tablespace_name, segment_created, status,
        last_analyzed, global_stats, num_rows, leaf_blocks, distinct_keys,
        clustering_factor, blevel
      FROM all_ind_subpartitions
      WHERE index_owner = p_index_owner AND index_name = p_index_name
      AND partition_name = NVL(p_partition_name, partition_name)
    )
    LOOP
      rec.index_owner := r.index_owner;
      rec.index_name := r.index_name;
      rec.partition_name := r.partition_name;
      rec.subpartition_name := r.subpartition_name;
      rec.subpartition_position := r.subpartition_position;
      rec.high_value := r.high_value; -- LONG -> VARCHAR2
      rec.interval := r.interval;
      rec.compression := r.compression;
      rec.pct_free := r.pct_free;
      rec.ini_trans := r.ini_trans;
      rec.tablespace_name := r.tablespace_name;
      rec.segment_created := r.segment_created;
      rec.status := r.status;
      rec.last_analyzed := r.last_analyzed;
      rec.global_stats := r.global_stats;
      rec.num_rows := r.num_rows;
      rec. leaf_blocks := r.leaf_blocks;
      rec.distinct_keys := r.distinct_keys;
      rec.clustering_factor := r.clustering_factor;
      rec.blevel := r.blevel;

      PIPE ROW(rec) ;
    END LOOP;

    RETURN;
  END get_index_subpartition_info;
  
  
  FUNCTION get_column_info
  (
    p_owner         IN VARCHAR2,
    p_table_list    IN VARCHAR2
  ) RETURN tab_column_info PIPELINED IS
    rec rec_column_info;
  BEGIN
    FOR r IN
    (
      SELECT *
      FROM v_all_columns
      WHERE owner = p_owner
      AND table_name IN (SELECT COLUMN_VALUE FROM TABLE(SPLIT_STRING(p_table_list)))
      ORDER BY table_name, column_id
    )
    LOOP
      rec.owner := r.owner;
      rec.table_name := r.table_name;
      rec.column_id := r.column_id;
      rec.column_name := r.column_name;
      rec.data_type := r.data_type;
      rec.nullable := r.nullable;
      rec.default_value := r.data_default;

      PIPE ROW (rec) ;
    END LOOP;

    RETURN;
  END get_column_info;
  
  
  FUNCTION schema_space_usage_kb(p_schema IN VARCHAR2) RETURN INTEGER IS
    n_kb INTEGER;
  BEGIN
    xl.begin_action('GET_SCHEMA_SPACE_USAGE_KB', 'Calculating the amount of disk space used by '||p_schema||' objects', 5, $$PLSQL_UNIT) ;
    SELECT ROUND (SUM(bytes)/1024) INTO n_kb
    FROM dba_segments
    WHERE owner = p_schema;
    xl.end_action('N_KB='||n_kb) ;
  RETURN n_kb;
  END schema_space_usage_kb;
  
  
  FUNCTION all_users_and_roles RETURN tab_users_roles PIPELINED IS
    rec rec_user_role;
  BEGIN
    FOR r in
    (
      SELECT * FROM
      (
        SELECT username name, 'USER' user_or_role FROM dba_users
        UNION ALL
        SELECT role, 'ROLE' FROM dba_roles
      )
      ORDER BY name
    )
    LOOP
      rec.name := r.name;
      rec.user_or_role := r.user_or_role;
      PIPE ROW (rec) ;
    END LOOP;
  END all_users_and_roles;
  
  
  FUNCTION all_object_access_privs RETURN tab_obj_access_privs PIPELINED IS
  BEGIN
    FOR r IN
    (
      SELECT p.owner, p.table_name, p.type, p.grantee, p.privilege, p.grantable
      FROM dba_tab_privs p
      WHERE p.owner not IN ('SYS', 'SYSTEM', 'APPQOSSYS', 'AUDSYS', 'DBSNMP', 'IMADVISOR', 'OUTLN', 'XDB', 'WMSYS')
      ORDER BY p.owner, p.table_name, p.grantee, p.privilege
    )
    LOOP
      PIPE ROW(r) ;
    END LOOP;
    
    RETURN;
  END all_object_access_privs;
  
  
  FUNCTION get_view_text(p_owner IN VARCHAR2, p_view_name IN VARCHAR2) RETURN CLOB IS
    long_text LONG;
    clob_text CLOB;
  BEGIN
    SELECT text INTO long_text
    FROM all_views v
    WHERE owner = p_owner AND view_name = p_view_name;
    
    clob_text := long_text;
    
    RETURN clob_text;
  END get_view_text;
END;
/