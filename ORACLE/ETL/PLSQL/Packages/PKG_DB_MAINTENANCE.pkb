CREATE OR REPLACE PACKAGE BODY pkg_db_maintenance AS
/*
  2021-11-18, O. Khaykin: added INI_TRANS and PCT_FREE to REC_PARTITION_INFO and REC_SUBPARTITION_INFO.
*/
  PROCEDURE exec_sql(p_sql IN VARCHAR2, p_force IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    IF LENGTH(p_sql) > 255 THEN
      xl.begin_action('Executing SQL', p_sql);
    ELSE
      xl.begin_action(p_sql, 'Started');
    END IF;
    
    EXECUTE IMMEDIATE p_sql;
    xl.end_action; 
  EXCEPTION
   WHEN OTHERS THEN
    xl.end_action(SQLERRM);
    IF NOT p_force THEN
      RAISE;
    END IF;
  END;
  
  
  FUNCTION get_column_definitions(p_column_definitions IN VARCHAR2) RETURN tab_column_definitions PIPELINED IS
    
    FUNCTION get_col_dfn(p_col_dfn IN VARCHAR2) RETURN rec_column_definition IS
      ret   rec_column_definition;
      n     PLS_INTEGER;
      m     PLS_INTEGER;
    BEGIN
      m := INSTR(p_col_dfn, ':', 1, 1);
      n := INSTR(p_col_dfn, ':', 1, 2);
      
      ret.column_name := SUBSTR(p_col_dfn, 1, m-1);
      ret.data_type := SUBSTR(p_col_dfn, m+1, n-m-1);
      ret.nullable := SUBSTR(p_col_dfn, n+1);
      
      RETURN ret;
    END;
  BEGIN
    FOR r IN
    (
      SELECT COLUMN_VALUE cdef
      FROM TABLE(split_string(p_column_definitions))
    )
    LOOP
      PIPE ROW(get_col_dfn(r.cdef));
    END LOOP;
    
    RETURN;
  END;
  
  
  PROCEDURE add_columns
  (
    p_column_definitions IN VARCHAR2,
    p_table_list         IN VARCHAR2
  ) IS
    cmd_list TAB_V256;
  BEGIN
    SELECT
      'ALTER TABLE '||tl.COLUMN_VALUE||
      CASE WHEN utc.owner IS NULL THEN ' ADD ' ELSE ' MODIFY ' END ||
      tcd.column_name||' '||tcd.data_type||
      CASE WHEN tcd.nullable <> NVL(utc.nullable, 'NULL') THEN CASE tcd.nullable WHEN 'N' THEN ' NOT NULL' ELSE ' NULL' END END cmd
    BULK COLLECT INTO cmd_list 
    FROM TABLE(etladmin.pkg_db_maintenance.get_column_definitions(p_column_definitions)) tcd
    CROSS JOIN TABLE(split_string(p_table_list)) tl
    LEFT JOIN v_all_columns utc
      ON utc.owner = SYS_CONTEXT('USERENV','CURRENT_USER')
     AND utc.table_name = UPPER(tl.COLUMN_VALUE)
     AND utc.column_name = UPPER(tcd.column_name)
    WHERE utc.owner IS NULL OR UPPER(tcd.data_type) <> REPLACE(REPLACE(utc.data_type, ' CHAR)', ')'), ' BYTE)', ')') OR utc.nullable <> tcd.nullable;
     
    FOR I in 1..cmd_list.COUNT LOOP
      exec_sql(cmd_list(i));
    END LOOP;
  END;
  
  
  -- This function returns a detaset that describes table [sub-]partitions
  FUNCTION get_partition_info
  (
    i_table_owner         IN VARCHAR2,
    i_table_name          IN VARCHAR2,
    i_partition_name      IN VARCHAR2 DEFAULT NULL,
    i_partition_position  IN NUMBER DEFAULT NULL
  ) RETURN tab_partition_info PIPELINED IS
    rec                   rec_partition_info;
  BEGIN
    FOR r IN
    (
      SELECT
        table_owner, table_name, tablespace_name,
        partition_name, partition_position, high_value,
        compress_for, ini_trans, pct_free, blocks AS num_blocks, num_rows, last_analyzed
      FROM all_tab_partitions
      WHERE table_owner = i_table_owner AND table_name = i_table_name
      AND partition_name = NVL(i_partition_name, partition_name)
      AND partition_position = NVL(i_partition_position, partition_position)
    )
    LOOP
      rec.table_owner := r.table_owner;
      rec.table_name := r.table_name;
      rec.tablespace_name := r.tablespace_name;
      rec.partition_name := r.partition_name;
      rec.partition_position := r.partition_position;
      rec.high_value := r.high_value; -- LONG -> VARCHAR2
      rec.compress_for := r.compress_for;
      rec.num_blocks := r.num_blocks;
      rec.ini_trans := r.ini_trans;
      rec.pct_free := r.pct_free; 
      rec.num_rows := r.num_rows;
      rec.last_analyzed := r.last_analyzed;
      
      PIPE ROW(rec);
    END LOOP;
  END;
 

  FUNCTION get_subpartition_info
  (
    i_table_owner         IN VARCHAR2,
    i_table_name          IN VARCHAR2,
    i_partition_name      IN VARCHAR2 DEFAULT NULL
  ) RETURN tab_subpartition_info PIPELINED IS
    rec rec_subpartition_info;
  BEGIN
    FOR r IN
    (
      SELECT
        table_owner, table_name, tablespace_name,
        partition_name, subpartition_name, subpartition_position, high_value,
        compress_for, ini_trans, pct_free, blocks AS num_blocks, num_rows, last_analyzed
      FROM all_tab_subpartitions
      WHERE table_owner = i_table_owner AND table_name = i_table_name
      AND partition_name = NVL(i_partition_name, partition_name)
    )
    LOOP
      rec.table_owner := r.table_owner;
      rec.table_name := r.table_name;
      rec.tablespace_name := r.tablespace_name;
      rec.partition_name := r.partition_name;
      rec.subpartition_name := r.subpartition_name;
      rec.subpartition_position := r.subpartition_position;
      rec.high_value := r.high_value; -- LONG -> VARCHAR2
      rec.compress_for := r.compress_for;
      rec.ini_trans := r.ini_trans;
      rec.pct_free := r.pct_free; 
      rec.num_blocks := r.num_blocks;
      rec.num_rows := r.num_rows;
      rec.last_analyzed := r.last_analyzed;
     
      PIPE ROW(rec);
    END LOOP;
  END;

  -- This function returns a detaset that describes table [sub-]partitions
  FUNCTION get_index_partition_info
  (
    p_index_owner         IN VARCHAR2,
    p_index_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL,
    p_partition_position  IN NUMBER DEFAULT NULL
  ) RETURN tab_index_partition_info PIPELINED IS
    rec                   rec_index_partition_info;
  BEGIN
    FOR r IN
    (
      SELECT
        index_owner, index_name
        , partition_name, partition_position, high_value
        , status, composite, interval, blevel, num_rows, distinct_keys, clustering_factor
        , segment_created, leaf_blocks, compression, ini_trans, tablespace_name, last_analyzed, global_stats
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
      rec.high_value := r.high_value;
      rec.status := r.status;
      rec.composite := r.composite;
      rec.interval := r.interval;
      rec.blevel := r.blevel;
      rec.num_rows := r.num_rows;
      rec.distinct_keys := r.distinct_keys;
      rec.clustering_factor := r.clustering_factor;
      rec.segment_created := r.segment_created;
      rec.leaf_blocks := r.leaf_blocks;
      rec.compression := r.compression;
      rec.ini_trans := r.ini_trans;
      rec.tablespace_name := r.tablespace_name;
      rec.last_analyzed := r.last_analyzed;
      rec.global_stats := r.global_stats;
      
      PIPE ROW(rec);
    END LOOP;
  END;
  
END;
/