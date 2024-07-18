CREATE OR REPLACE PACKAGE pkg_db_info AS
  TYPE rec_partition_info IS RECORD
  (
    table_owner             VARCHAR2(30),
    table_name              VARCHAR2(128),
    partition_name          VARCHAR2(128),
    partition_position      INTEGER,
    high_value              VARCHAR2(255),
    interval                VARCHAR2(3),
    composite               VARCHAR2(3),
    indexing                VARCHAR2(4),
    subpartition_count      INTEGER,
    compress_for            VARCHAR2(30),
    ini_trans               NUMBER(3),
    pct_free                NUMBER(2) ,
    tablespace_name         VARCHAR2(30),
    segment_created         VARCHAR2(4),
    last_analyzed           DATE,
    num_rows                INTEGER,
    blocks                  INTEGER,
    inmemory_priority       VARCHAR2(30),
    inmemory_distribute     VARCHAR2(30),
    inmemory_compression    VARCHAR2(30)
  );
  
  TYPE tab_partition_info IS TABLE OF rec_partition_info;

  TYPE rec_subpartition_info IS RECORD
  (
    table_owner             VARCHAR2(30),
    table_name              VARCHAR2(128),
    partition_name          VARCHAR2(128),
    subpartition_name       VARCHAR2(128),
    subpartition_position   INTEGER,
    high_value              VARCHAR2(255),
    interval                VARCHAR2(3),
    compress_for            VARCHAR2(30),
    ini_trans               NUMBER (3),
    pct_free                NUMBER (2),
    tablespace_name         VARCHAR2(30),
    segment_created         VARCHAR2(4),
    last_analyzed           DATE,
    num_rows                INTEGER,
    blocks                  INTEGER,
    inmemory_priority       VARCHAR2(30),
    inmemory_distribute     VARCHAR2(30) ,
    inmemory_compression    VARCHAR2(30)
  );
  
  TYPE tab_subpartition_info IS TABLE OF rec_subpartition_info;

  TYPE rec_index_partition_info IS RECORD
  (
    index_owner             VARCHAR2(128),
    index_name              VARCHAR2(128),
    partition_name          VARCHAR2(128),
    partition_position      INTEGER,
    high_value              VARCHAR2(256),
    interval                VARCHAR2(3),
    composite               VARCHAR2(3),
    compression             VARCHAR2(13),
    pct_free                NUMBER(3),
    ini_trans               NUMBER(3),
    tablespace_name         VARCHAR2(30),
    segment_created         VARCHAR2(4),
    status                  VARCHAR2(8),
    last_analyzed           DATE,
    global_stats            VARCHAR2(3),
    num_rows                INTEGER,
    leaf_blocks             INTEGER,
    distinct_keys           INTEGER,
    clustering_factor       INTEGER,
    blevel                  NUMBER(5)
  );
  
  TYPE tab_index_partition_info IS TABLE OF rec_index_partition_info;

  TYPE rec_index_subpartition_info IS RECORD
  (
    index_owner             VARCHAR2(128),
    index_name              VARCHAR2(128),
    partition_name          VARCHAR2(128),
    subpartition_name       VARCHAR2(128),
    subpartition_position   INTEGER,
    high_value              VARCHAR2(256),
    interval                VARCHAR2(3),
    compression             VARCHAR2(13),
    pct_free                NUMBER(3),
    ini_trans               NUMBER(3),
    tablespace_name         VARCHAR2(128),
    segment_created         VARCHAR2(4),
    status                  VARCHAR2(8),
    last_analyzed           DATE,
    global_stats            VARCHAR2(3),
    num_rows                INTEGER,
    leaf_blocks             INTEGER,
    distinct_keys           INTEGER,
    clustering_factor       INTEGER,
    blevel                  INTEGER
  );
  
  TYPE tab_index_subpartition_info IS TABLE OF rec_index_subpartition_info;

  TYPE rec_column_info IS RECORD
  (
    owner                   VARCHAR2(128),
    table_name              VARCHAR2(128),
    column_id               NUMBER(3),
    column_name             VARCHAR2(128),
    data_type               VARCHAR2(64),
    nullable                CHAR(1),
    default_value           VARCHAR2(256)
  );
  
  TYPE tab_column_info IS TABLE OF rec_column_info;
  
  TYPE rec_user_role IS RECORD
  (
    name                    VARCHAR2(30),
    user_or_role            VARCHAR2(5)
  );
  
  TYPE tab_users_roles IS TABLE OF rec_user_role;
  
  TYPE rec_obj_access_privilege IS RECORD
  (
    owner                   VARCHAR2(30),
    object_name             VARCHAR2(128),
    object_type             VARCHAR2(30),
    grantee                 VARCHAR2(30),
    privilege               VARCHAR2(30),
    grantable               VARCHAR2(3)
  );

  TYPE tab_obj_access_privs IS TABLE OF rec_obj_access_privilege;

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

  FUNCTION get_column_info
  (
    p_owner               IN VARCHAR2,
    p_table_list          IN VARCHAR2
  ) RETURN tab_column_info PIPELINED;

  FUNCTION schema_space_usage_kb(p_schema IN VARCHAR2) RETURN INTEGER;

  FUNCTION all_users_and_roles RETURN tab_users_roles PIPELINED;

  FUNCTION all_object_access_privs RETURN tab_obj_access_privs PIPELINED;

  FUNCTION get_view_text(p_owner IN VARCHAR2, p_view_name IN VARCHAR2) RETURN CLOB;
END;
/

GRANT EXECUTE ON pkg_db_info TO PUBLIC;
CREATE OR REPLACE PUBLIC SYNONYM dbi FOR pkg db info;
