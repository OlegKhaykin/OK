CREATE OR REPLACE PACKAGE BODY pkg_db_maintenance AS
/*
  22-Feb-2022, OK: added procedure TRUNCATE_TABLES.
  09-Feb-2022, O. Khaykin: new version that only calls procedures from the common PKG_DB_MAINTENANCE_API package. 
*/
  PROCEDURE add_columns
  (
    p_column_definitions IN VARCHAR2, -- for example: 'COL1:INTEGER:N, COL2:VARCHAR2:Y'
    p_table_list         IN VARCHAR2  -- comma-separated list of tables
  ) IS
  BEGIN
    api.add_columns(p_column_definitions, p_table_list);
  END;
  
  PROCEDURE drop_partitions
  (
    p_table_list  IN VARCHAR2,  -- comma-separated list of tables, starting with the "children" tables
    p_up_to       IN VARCHAR2   -- upper limit (non-inclusive)
  ) IS
  BEGIN
    api.drop_partitions(p_table_list, p_up_to);
  END;
  
  PROCEDURE drop_subpartitions
  (
    p_table_list  IN VARCHAR2,  -- comma-separated list of tables, starting with the "children" tables
    p_up_to       IN VARCHAR2   -- upper limit (non-inclusive)
  ) IS
  BEGIN
    api.drop_subpartitions(p_table_list, p_up_to);
  END;
  
  PROCEDURE compress_data -- to compress data
  (
    p_condition         IN VARCHAR2,-- for example: 'WHERE table_name=''MEBERDERIVEDFACT_UR'' AND high_value BETWEEN ''01-JAN-21'' AND ''31-DEC-22''';
    p_compress_type     IN VARCHAR2, -- for example: 'NOCOMPRESS', 'BASIC', 'OLTP', 'QUERY HIGH', etc.
    p_update_indexes    IN CHAR DEFAULT 'Y',
    p_deallocate_unused IN CHAR DEFAULT 'Y',
    p_tablespace        IN VARCHAR2 DEFAULT NULL,
    p_gather_stats      IN CHAR DEFAULT 'N'
  ) IS
  BEGIN
    api.compress_data(p_condition, p_compress_type, p_update_indexes, p_deallocate_unused, p_tablespace, p_gather_stats);
  END;

  PROCEDURE truncate_tables
  (
    p_table_list    IN VARCHAR2,
    p_drop_storage  IN CHAR DEFAULT 'ALL',
    p_cascade       IN CHAR DEFAULT 'N'
  ) IS
  BEGIN
    api.truncate_tables(p_table_list, p_drop_storage, p_cascade);
  END;
  
  PROCEDURE deallocate_unused_space -- to reclaim unused disk space
  (
    p_condition       IN VARCHAR2 -- for example: 'WHERE table_name=''PATHSENS'' AND RevalDate BETWEEN ''01-JAN-13'' AND ''31-DEC-13''';
  ) IS
  BEGIN
    api.deallocate_unused_space(p_condition);
  END;

  PROCEDURE compress_indexes -- to rebuild partitioned indexes as COMPRESSED
  (
    p_table_list  IN VARCHAR2 DEFAULT NULL, -- comma-separated list of tables
    p_index_list  IN VARCHAR2 DEFAULT NULL, -- comma-separated list of indexes
    p_force       IN CHAR DEFAULT 'N', -- if 'Y' then the indexes will be rebuilt even if their compression is already enabled
    p_tablespace  IN VARCHAR2 DEFAULT NULL -- tablespace to place new indexes into
  ) IS
  BEGIN
    api.compress_indexes(p_table_list, p_index_list, p_force, p_tablespace);
  END;
  
  PROCEDURE disable_index_partitions
  (
    p_condition IN VARCHAR2,
    p_comment   IN VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    api.disable_index_partitions(p_condition, p_comment);
  END;
  
  PROCEDURE enable_index_partitions
  (
    p_condition IN VARCHAR2,
    p_comment   IN VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    api.enable_index_partitions(p_condition, p_comment);
  END;
  
  PROCEDURE gather_stats
  (
    p_condition         IN VARCHAR2,
    p_degree            IN PLS_INTEGER DEFAULT NULL,
    p_granularity       IN VARCHAR2 DEFAULT NULL,
    p_estimate_pct      IN NUMBER DEFAULT NULL,
    p_cascade           IN BOOLEAN DEFAULT NULL,
    p_method_opt        IN VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    api.gather_stats(p_condition, p_degree, p_granularity, p_estimate_pct, p_cascade, p_method_opt);
  END;
  
  PROCEDURE set_stats_gather_prefs
  (
    p_pref_name   IN VARCHAR2,
    p_value       IN VARCHAR2,
    p_table_name  IN VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    api.set_stats_gather_prefs(p_pref_name, p_value, p_table_name);
  END;

END;
/