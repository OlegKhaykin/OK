CREATE OR REPLACE PACKAGE pkg_db_maintenance_api AUTHID CURRENT_USER AS
/*
  Description: this package contains procedures for various DB maintenance tasks.
  
  Note: This is an API package that is executed with the caller privileges.
        In each schema, we need to created a "stub" package that will
        call the procedures from this API package using the schema privileges.

  History of changes (newest to oldest):
  ------------------------------------------------------------------------------
  23-Feb-2022, OK: added procedure TRUNCATE_TABLES.
  08-Feb-2022, OK: incorporated changes made in the last 6 years.
  02-May-2016, OK: original version based on the old RESULTS.PKG_DB_MAINTENANCE.  
*/
  TYPE rec_partition_info IS RECORD
  (
    table_owner           VARCHAR2(30),
    table_name            VARCHAR2(128),
    partition_name        VARCHAR2(128),
    partition_position    INTEGER,
    high_value            VARCHAR2(255),
    interval              VARCHAR2(3),
    composite             VARCHAR2(3),
    subpartition_count    INTEGER,
    compress_for          VARCHAR2(30),
    ini_trans             NUMBER(3),
    pct_free              NUMBER(2),
    tablespace_name       VARCHAR2(30),
    segment_created       VARCHAR2(4),
    last_analyzed         DATE,
    num_rows              INTEGER,
    blocks                INTEGER
  );
  
  TYPE tab_partition_info IS TABLE OF rec_partition_info;
  
  TYPE rec_subpartition_info IS RECORD
  (
    table_owner           VARCHAR2(30),
    table_name            VARCHAR2(128),
    partition_name        VARCHAR2(128),
    subpartition_name     VARCHAR2(128),
    subpartition_position INTEGER,
    high_value            VARCHAR2(255),
    interval              VARCHAR2(3),
    compress_for          VARCHAR2(30),
    ini_trans             NUMBER(3),
    pct_free              NUMBER(2),
    tablespace_name       VARCHAR2(30),
    segment_created       VARCHAR2(4),
    last_analyzed         DATE,
    num_rows              INTEGER,
    blocks                INTEGER
  );
  
  TYPE tab_subpartition_info IS TABLE OF rec_subpartition_info;
  
  TYPE rec_index_partition_info IS RECORD
  (
    index_owner           VARCHAR2(128),
    index_name            VARCHAR2(128),
    partition_name        VARCHAR2(128),
    partition_position	  INTEGER,
    high_value            VARCHAR2(256),
    interval              VARCHAR2(3),
    composite             VARCHAR2(3),
    compression           VARCHAR2(13),
    pct_free              NUMBER(3),
    ini_trans             NUMBER(3),
    tablespace_name       VARCHAR2(30),
    segment_created       VARCHAR2(4),
    status                VARCHAR2(8),
    last_analyzed         DATE,
    global_stats          VARCHAR2(3),
    num_rows              INTEGER,
    leaf_blocks           INTEGER,
    distinct_keys         INTEGER,
    clustering_factor     INTEGER,
    blevel                NUMBER(5)
  );
  
  TYPE tab_index_partition_info IS TABLE OF rec_index_partition_info;
  
  TYPE rec_index_subpartition_info IS RECORD
  (
    index_owner           VARCHAR2(128),
    index_name            VARCHAR2(128),
    partition_name        VARCHAR2(128),
    subpartition_name     VARCHAR2(128),
    subpartition_position INTEGER,
    high_value            VARCHAR2(256),
    interval              VARCHAR2(3),
    compression           VARCHAR2(13),
    pct_free              NUMBER(3),
    ini_trans             NUMBER(3),
    tablespace_name       VARCHAR2(128),
    segment_created       VARCHAR2(4),
    status                VARCHAR2(8),
    last_analyzed         DATE,
    global_stats          VARCHAR2(3),
    num_rows              INTEGER,
    leaf_blocks           INTEGER,
    distinct_keys         INTEGER,
    clustering_factor     INTEGER,
    blevel                INTEGER
  );
  
  TYPE tab_index_subpartition_info IS TABLE OF rec_index_subpartition_info;
  
  TYPE rec_column_definition IS RECORD
  (
    column_name VARCHAR2(128),
    data_type   VARCHAR2(30),
    nullable    CHAR(1) 
  );
  
  TYPE tab_column_definitions IS TABLE OF rec_column_definition;
  
  FUNCTION get_column_definitions(p_column_definitions IN VARCHAR2) RETURN tab_column_definitions PIPELINED;
  
  PROCEDURE add_columns
  (
    p_column_definitions IN VARCHAR2,
    p_table_list         IN VARCHAR2
  );
  
  FUNCTION get_partition_info
  (
    p_table_owner         IN VARCHAR2,
    p_table_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL,
    p_partition_position  IN NUMBER DEFAULT NULL
  ) RETURN tab_partition_info PIPELINED;
  
  FUNCTION get_subpartition_info
  (
    p_table_owner         IN VARCHAR2,
    p_table_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL
  ) RETURN tab_subpartition_info PIPELINED;
  
  FUNCTION get_index_partition_info
  (
    p_index_owner         IN VARCHAR2,
    p_index_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL,
    p_partition_position  IN NUMBER DEFAULT NULL
  ) RETURN tab_index_partition_info PIPELINED;
  
  FUNCTION get_index_subpartition_info
  (
    p_index_owner         IN VARCHAR2,
    p_index_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL
  ) RETURN tab_index_subpartition_info PIPELINED;
  
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
  
  PROCEDURE compress_data -- to compress data
  (
    p_condition         IN VARCHAR2, -- for example: 'WHERE table_name=''MEMBERDERIVEDFACT_UR'' AND high_value BETWEEN ''01-JAN-21'' AND ''31-DEC-22'''
    p_compress_type     IN VARCHAR2, -- for example: 'NOCOMPRESS', 'BASIC', 'OLTP', 'QUERY HIGH', etc.
    p_update_indexes    IN CHAR DEFAULT 'Y',
    p_deallocate_unused IN CHAR DEFAULT 'Y',
    p_tablespace        IN VARCHAR2 DEFAULT NULL,
    p_gather_stats      IN CHAR DEFAULT 'N'
  );
  
  PROCEDURE truncate_tables
  (
    p_table_list    IN VARCHAR2,
    p_drop_storage  IN CHAR DEFAULT 'ALL',
    p_cascade       IN CHAR DEFAULT 'N'
  );
    
  PROCEDURE deallocate_unused_space -- to reclaim unused disk space
  (
    p_condition       IN VARCHAR2 -- for example: 'WHERE table_name=''MEMBERDERIVEDFACT_UR'' AND high_value BETWEEN ''01-JAN-21'' AND ''31-DEC-22'''
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
END pkg_db_maintenance_api;
/

GRANT EXECUTE ON pkg_db_maintenance_api TO PUBLIC;