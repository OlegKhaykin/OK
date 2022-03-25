CREATE OR REPLACE PACKAGE pkg_db_maintenance AS
/*
  Description: this package contains procedures for various DB maintenance tasks.
  
  04-Mar-2022, OK: per Aanchal's request, commented-out functionality that is not fully tested.
  22-Feb-2022, OK: added procedure TRUNCATE_TABLES.
*/
  PROCEDURE add_columns
  (
    p_column_definitions IN VARCHAR2, -- for example: 'COL1:INTEGER:N, COL2:VARCHAR2:Y'
    p_table_list         IN VARCHAR2  -- comma-separated list of tables
  );
  
  PROCEDURE drop_partitions
  (
    p_table_list  IN VARCHAR2,  -- comma-separated list of tables, starting with the "children" tables
    p_up_to       IN VARCHAR2   -- upper limit (non-inclusive)
  );
  
  PROCEDURE drop_subpartitions
  (
    p_table_list  IN VARCHAR2,  -- comma-separated list of tables, starting with the "children" tables
    p_up_to       IN VARCHAR2   -- upper limit (non-inclusive)
  );
  
  PROCEDURE truncate_tables
  (
    p_table_list    IN VARCHAR2,
    p_drop_storage  IN CHAR DEFAULT 'ALL',
    p_cascade       IN CHAR DEFAULT 'N'
  );
/*  
  PROCEDURE compress_data -- to compress data
  (
    p_condition         IN VARCHAR2, -- for example: 'WHERE table_name=''MEMBERHEALTHSTATE_HIST'' AND eval_date(high_value) BETWEEN DATE ''2021-01-01'' AND DATE ''2022-12-31'''
    p_compress_type     IN VARCHAR2, -- for example: 'NOCOMPRESS', 'BASIC', 'OLTP', 'QUERY HIGH', etc.
    p_update_indexes    IN CHAR DEFAULT 'Y',
    p_deallocate_unused IN CHAR DEFAULT 'Y',
    p_tablespace        IN VARCHAR2 DEFAULT NULL,
    p_gather_stats      IN CHAR DEFAULT 'N'
  );
  
  PROCEDURE compress_indexes -- to rebuild partitioned indexes as COMPRESSED
  (
    p_table_list  IN VARCHAR2 DEFAULT NULL, -- comma-separated list of tables
    p_index_list  IN VARCHAR2 DEFAULT NULL, -- comma-separated list of indexes
    p_force       IN CHAR DEFAULT 'N', -- if 'Y' then the indexes will be rebuilt even if their compression is already enabled
    p_tablespace  IN VARCHAR2 DEFAULT NULL -- tablespace to place new indexes into
  );
  
  PROCEDURE disable_index_partitions
  (
    p_condition IN VARCHAR2,
    p_comment   IN VARCHAR2 DEFAULT NULL
  );
  
  PROCEDURE enable_index_partitions
  (
    p_condition IN VARCHAR2,
    p_comment   IN VARCHAR2 DEFAULT NULL
  );
  
  PROCEDURE deallocate_unused_space -- to reclaim unused disk space
  (
    p_condition       IN VARCHAR2 -- for example: 'WHERE table_name=''MEMBERHEALTHSTATE_HIST'' AND eval_date(high_value) BETWEEN DATE ''2021-01-01'' AND DATE ''2022-12-31'''
  );
*/
  PROCEDURE gather_stats
  (
    p_condition         IN VARCHAR2,
    p_degree            IN PLS_INTEGER DEFAULT NULL,
    p_granularity       IN VARCHAR2 DEFAULT NULL,
    p_estimate_pct      IN NUMBER DEFAULT NULL,
    p_cascade           IN BOOLEAN DEFAULT NULL,
    p_method_opt        IN VARCHAR2 DEFAULT NULL
  );
  
  PROCEDURE set_stats_gather_prefs
  (
    p_pref_name   IN VARCHAR2,
    p_value       IN VARCHAR2,
    p_table_name  IN VARCHAR2 DEFAULT NULL
  );
END pkg_db_maintenance;
/

CREATE OR REPLACE SYNONYM dbm FOR pkg_db_maintenance;
CREATE OR REPLACE SYNONYM api FOR etladmin.pkg_db_maintenance_api;

GRANT EXECUTE ON pkg_db_maintenance TO etladmin, DBA;
