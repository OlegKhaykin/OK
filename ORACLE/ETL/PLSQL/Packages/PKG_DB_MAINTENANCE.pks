CREATE OR REPLACE PACKAGE pkg_db_maintenance AUTHID CURRENT_USER AS
/*
  2021-11-18, O. Khaykin: added INI_TRANS and PCT_FREE to REC_PARTITION_INFO and REC_SUBPARTITION_INFO.
*/
  TYPE rec_partition_info IS RECORD
  (
    table_owner           VARCHAR2(30),
    table_name            VARCHAR2(128),
    tablespace_name       VARCHAR2(30),
    partition_name        VARCHAR2(128),
    partition_position    NUMBER(6),
    high_value            VARCHAR2(255),
    compress_for          VARCHAR2(30),
    ini_trans             NUMBER(3),
    pct_free              NUMBER(2),
    num_blocks            NUMBER(10),
    num_rows              INTEGER,
    last_analyzed         DATE
  );
  
  TYPE tab_partition_info IS TABLE OF rec_partition_info;
  
  TYPE rec_subpartition_info IS RECORD
  (
    table_owner           VARCHAR2(30),
    table_name            VARCHAR2(128),
    tablespace_name       VARCHAR2(30),
    partition_name        VARCHAR2(128),
    subpartition_name     VARCHAR2(128),
    subpartition_position NUMBER(6),
    high_value            VARCHAR2(255),
    compress_for          VARCHAR2(30),
    ini_trans             NUMBER(3),
    pct_free              NUMBER(2),
    num_blocks            NUMBER(10),
    num_rows              INTEGER,
    last_analyzed         DATE
  );
  
  TYPE tab_subpartition_info IS TABLE OF rec_subpartition_info;
  
  TYPE rec_index_partition_info IS RECORD
  (
    index_owner           VARCHAR2(128),
    index_name            VARCHAR2(128),
    partition_name        VARCHAR2(128),
    partition_position	  NUMBER(3),
    high_value            VARCHAR2(256),
    status                VARCHAR2(8),
    composite             VARCHAR2(3),
    interval              VARCHAR2(3),
    blevel                NUMBER(5),
    num_rows              INTEGER,
    distinct_keys         INTEGER,
    clustering_factor     INTEGER,
    segment_created       VARCHAR2(3),
    leaf_blocks           INTEGER,
    compression           VARCHAR2(13),
    ini_trans             NUMBER(3),
    tablespace_name       VARCHAR2(30),
    last_analyzed         DATE,
    global_stats          VARCHAR2(3)
  );
  
  TYPE tab_index_partition_info IS TABLE OF rec_index_partition_info;
  
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
    i_table_owner         IN VARCHAR2,
    i_table_name          IN VARCHAR2,
    i_partition_name      IN VARCHAR2 DEFAULT NULL,
    i_partition_position  IN NUMBER DEFAULT NULL
  ) RETURN tab_partition_info PIPELINED;
  
  FUNCTION get_subpartition_info
  (
    i_table_owner         IN VARCHAR2,
    i_table_name          IN VARCHAR2,
    i_partition_name      IN VARCHAR2 DEFAULT NULL
  ) RETURN tab_subpartition_info PIPELINED;
  
  FUNCTION get_index_partition_info
  (
    p_index_owner         IN VARCHAR2,
    p_index_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL,
    p_partition_position  IN NUMBER DEFAULT NULL
  ) RETURN tab_index_partition_info PIPELINED;
END;
/

CREATE OR REPLACE SYNONYM dbm FOR pkg_db_maintenance;
GRANT EXECUTE ON pkg_db_maintenance TO PUBLIC;
