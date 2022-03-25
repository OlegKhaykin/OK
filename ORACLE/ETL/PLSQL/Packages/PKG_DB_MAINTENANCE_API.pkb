CREATE OR REPLACE PACKAGE BODY pkg_db_maintenance_api AS
/*
  Description: this package contains procedures for various DB maintenance tasks.
  
  Note: This is an API package that is executed with caller privileges.
        In each schema, we need to create a caller (stub) package that will
        call the procedures from this API package using schema privileges.

  History of changes (newest to oldest):
  ------------------------------------------------------------------------------
  15-Mar-2022, OK: bug fix in DROP_(SUB)PARTITIOINS: stop if LIST-(sub)partitioning and high value = "up to limit".
  12-Mar-2022, OK: improved logging in several procedures.
  08-Mar-2022, OK: bug fix in GATHER_STATS and ANALYZE_TABLE_PARTITION.
  23-Feb-2022, OK: added procedure TRUNCATE_TABLES.
  08-Feb-2022, OK: incorporated changes made in the last 6 years.
  09-May-2016, OK: COMPRESS_DATA can now work with non-partitioned tables.
*/
  gv_sql        VARCHAR2(1000);
  gv_schema     VARCHAR2(30);
  mb_before     NUMBER;
  mb_after      NUMBER;
  mb_diff       NUMBER;
  rec           v_table_partition_info%ROWTYPE;
  tab_fks       tab_name_values;
  
  PROCEDURE set_session_params IS
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
    EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DDL';
    --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_COMP = BINARY';
    
    gv_schema := SYS_CONTEXT('USERENV','CURRENT_USER');
  END;

/*  
  PROCEDURE reset_session_params IS
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_COMP = LINGUISTIC';
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_SORT = BINARY_CI';
  END;
*/  
  
  PROCEDURE exec_sql(p_sql IN VARCHAR2, p_force IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    xl.begin_action('EXEC_SQL', p_sql, 1, $$PLSQL_UNIT);
    EXECUTE IMMEDIATE p_sql;
    xl.end_action; 
  EXCEPTION
   WHEN OTHERS THEN
    xl.end_action(SQLERRM);
    IF NOT p_force THEN
      RAISE;
    END IF;
  END;
  
  
  PROCEDURE analyze_table_partition
  (
    p_table_name      IN VARCHAR2,
    p_partition_name  IN VARCHAR2 DEFAULT NULL,
    p_degree          IN PLS_INTEGER DEFAULT NULL,
    p_granularity     IN VARCHAR2 DEFAULT NULL,
    p_estimate_pct    IN NUMBER DEFAULT NULL,
    p_cascade         IN BOOLEAN DEFAULT NULL,
    p_method_opt      IN VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    xl.begin_action
    (
      'ANALYZE_TABLE_PARTITION',
      'p_degree='||p_degree||
      ', p_granularity='||p_granularity||
      ', p_estimate_pct='||p_estimate_pct||
      ', p_cascade='||case when p_cascade then 'TRUE' when not p_cascade then 'FALSE' else 'NULL' end||
      ', p_method_opt='||p_method_opt,
      5, $$PLSQL_UNIT
    );
    dbms_stats.gather_table_stats
    (
      ownname => gv_schema,
      tabname => p_table_name,
      partname => p_partition_name,
      degree => NVL(p_degree, eval_number(dbms_stats.get_prefs('DEGREE', gv_schema, p_table_name))),
      granularity => NVL(p_granularity, dbms_stats.get_prefs('GRANULARITY', gv_schema, p_table_name)),
      estimate_percent => NVL(p_estimate_pct, eval_number(dbms_stats.get_prefs('ESTIMATE_PERCENT', gv_schema, p_table_name))),
      cascade => NVL(p_cascade, eval_boolean(dbms_stats.get_prefs('CASCADE', gv_schema, p_table_name))),
      method_opt => NVL(p_method_opt, dbms_stats.get_prefs('METHOD_OPT', gv_schema, p_table_name))
    );
    xl.end_action;
  END;        
  
  -- This private procedure DEALLOCATE_UNUSED is called from public procedures
  -- COMPRESS_DATA and DEALOCATE_UNUSED_SPACE to deallocate segment space above high water mark 
  PROCEDURE deallocate_unused
  (
    p_table_name        IN VARCHAR2,
    p_partition_name    IN VARCHAR2 DEFAULT NULL,
    p_subpartition_name IN VARCHAR2 DEFAULT NULL,
    p_keep              IN PLS_INTEGER DEFAULT 65536 -- 64K
  ) IS
    n_total_blocks              PLS_INTEGER;
    n_total_bytes               PLS_INTEGER;
    n_unused_blocks             PLS_INTEGER;
    n_unused_bytes              PLS_INTEGER;
    n_last_used_extent_file_id  PLS_INTEGER;
    n_last_used_extent_block_id PLS_INTEGER;
    n_last_used_block           PLS_INTEGER;
    v_segment_type              VARCHAR2(30);
    v_part_name                 VARCHAR2(30);
  BEGIN
    v_segment_type :=
    CASE
      WHEN p_subpartition_name IS NOT NULL THEN ' SUBPARTITION'
      WHEN p_partition_name IS NOT NULL THEN ' PARTITION'
    END;
    
    v_part_name := NVL(p_subpartition_name, p_partition_name);
    
    xl.begin_action('Deallocating unused space', p_table_name||v_segment_type||' '||v_part_name); 
    
    DBMS_SPACE.UNUSED_SPACE
    (
      segment_owner => gv_schema,
      segment_name => p_table_name,
      partition_name => v_part_name,
      segment_type => 'TABLE'||v_segment_type,
      total_blocks => n_total_blocks,
      total_bytes => n_total_bytes,
      unused_blocks => n_unused_blocks,
      unused_bytes => n_unused_bytes,
      last_used_extent_file_id => n_last_used_extent_file_id,
      last_used_extent_block_id => n_last_used_extent_block_id,
      last_used_block => n_last_used_block
    );
    
    IF n_unused_bytes > p_keep THEN
      exec_sql
      (
        'ALTER TABLE '||p_table_name||
        CASE WHEN v_part_name IS NOT NULL THEN ' MODIFY'||v_segment_type||' '||v_part_name END ||
        ' DEALLOCATE UNUSED KEEP '||p_keep
      );
      xl.end_action;
    ELSE
      xl.end_action('Unused space is too small: '||n_unused_bytes||' bytes, skipping ...'); 
    END IF;
  END;
  
  
  PROCEDURE prepare_qry(p_condition IN VARCHAR2) IS
  BEGIN
    gv_sql := 'SELECT * 
      FROM v_table_partition_info '|| p_condition || '
      AND owner = '''||gv_schema||'''
      ORDER BY table_name, partition_position, subpartition_position';
  END;
  
  --================= Public Procedures and Functions: =========================
  --  
  FUNCTION get_column_definitions(p_column_definitions IN VARCHAR2) RETURN tab_column_definitions PIPELINED IS
    
    FUNCTION get_col_dfn(p_col_dfn IN VARCHAR2) RETURN rec_column_definition IS
      ret   rec_column_definition;
      n     PLS_INTEGER;
      m     PLS_INTEGER;
    BEGIN
      m := INSTR(p_col_dfn, ':', 1, 1);
      n := INSTR(p_col_dfn, ':', 1, 2);
      
      ret.column_name := TRIM(SUBSTR(p_col_dfn, 1, m-1));
      ret.data_type := TRIM(SUBSTR(p_col_dfn, m+1, n-m-1));
      ret.nullable := TRIM(SUBSTR(p_col_dfn, n+1));
      
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
      'ALTER TABLE '||t.COLUMN_VALUE||
      CASE WHEN c.owner IS NULL THEN ' ADD ' ELSE ' MODIFY ' END ||
      d.column_name||' '||d.data_type||
      CASE WHEN d.nullable <> NVL(c.nullable, 'NULL') THEN CASE d.nullable WHEN 'N' THEN ' NOT NULL' ELSE ' NULL' END END cmd
    BULK COLLECT INTO cmd_list 
    FROM TABLE(get_column_definitions(p_column_definitions))  d
    CROSS JOIN TABLE(split_string(p_table_list))              t
    LEFT JOIN v_all_columns                                   c
      ON c.owner = gv_schema
     AND c.table_name = UPPER(t.COLUMN_VALUE)
     AND c.column_name = UPPER(d.column_name)
    WHERE c.owner IS NULL OR UPPER(d.data_type) <> REPLACE(REPLACE(c.data_type, ' CHAR)', ')'), ' BYTE)', ')') OR c.nullable <> d.nullable;
     
    FOR I in 1..cmd_list.COUNT LOOP
      exec_sql(cmd_list(i));
    END LOOP;
  END;
  
  
  -- This function returns a detaset that describes table partitions
  FUNCTION get_partition_info
  (
    p_table_owner         IN VARCHAR2,
    p_table_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL,
    p_partition_position  IN NUMBER DEFAULT NULL
  ) RETURN tab_partition_info PIPELINED IS
    rec                   rec_partition_info;
  BEGIN
    FOR r IN
    (
      SELECT
        table_owner, table_name, 
        partition_name, partition_position, high_value, interval, composite,
        subpartition_count, compress_for, ini_trans, pct_free, 
        tablespace_name, segment_created, last_analyzed, blocks, num_rows
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

      PIPE ROW(rec);
    END LOOP;
  END;
 

  FUNCTION get_subpartition_info
  (
    p_table_owner         IN VARCHAR2,
    p_table_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL
  ) RETURN tab_subpartition_info PIPELINED IS
    rec rec_subpartition_info;
  BEGIN
    FOR r IN
    (
      SELECT
        table_owner, table_name, partition_name,
        subpartition_name, subpartition_position, high_value, interval,
        compress_for, ini_trans, pct_free, tablespace_name, segment_created,
        last_analyzed, num_rows, blocks
      FROM all_tab_subpartitions
      WHERE table_owner = p_table_owner AND table_name = p_table_name
      AND partition_name = NVL(p_partition_name, partition_name)
    )
    LOOP
      rec.table_owner := r.table_owner;
      rec.table_name := r.table_name;
      rec.partition_name := r.partition_name;
      rec.subpartition_name := r.subpartition_name;
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
      
      PIPE ROW(rec);
    END LOOP;
  END;
  
  
  -- This function returns a detaset that describes index partitions
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
      rec.high_value := r.high_value;
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
      
      PIPE ROW(rec);
    END LOOP;
    
    RETURN;
  END;
  
  
  FUNCTION get_index_subpartition_info
  (
    p_index_owner         IN VARCHAR2,
    p_index_name          IN VARCHAR2,
    p_partition_name      IN VARCHAR2 DEFAULT NULL
  ) RETURN tab_index_subpartition_info PIPELINED IS
    rec                   rec_index_subpartition_info;
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
      rec.high_value := r.high_value;
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
      rec.leaf_blocks := r.leaf_blocks;
      rec.distinct_keys := r.distinct_keys;
      rec.clustering_factor := r.clustering_factor;
      rec.blevel := r.blevel;
      
      PIPE ROW(rec);
    END LOOP;
    
    RETURN;
  END;
  
  
  PROCEDURE disable_referencing_fks(p_table_name IN VARCHAR2) IS
  BEGIN
    xl.begin_action('Disabling FKs referencing table', gv_schema||'.'||p_table_name, 1, $$PLSQL_UNIT);
    SELECT obj_name_value(fk.table_name, fk.constraint_name) BULK COLLECT INTO tab_fks
    FROM all_constraints pk
    JOIN all_constraints fk
      ON fk.r_owner = pk.owner
     AND fk.r_constraint_name = pk.constraint_name
     AND fk.status = 'ENABLED'
    WHERE pk.owner = gv_schema AND pk.table_name = p_table_name AND pk.constraint_type IN ('P','U');
    
    FOR i IN 1..tab_fks.COUNT LOOP
      exec_sql('ALTER TABLE '||tab_fks(i).name||' MODIFY CONSTRAINT '||tab_fks(i).value||' DISABLE');
    END LOOP;
    xl.end_action;
  END disable_referencing_fks;
  
  
  PROCEDURE enable_disabled_fks IS
  BEGIN
    xl.begin_action('Enabling disabled FKs', 'Started', 1, $$PLSQL_UNIT);
    FOR i IN 1..tab_fks.COUNT LOOP
      exec_sql('ALTER TABLE '||tab_fks(i).name||' MODIFY CONSTRAINT '||tab_fks(i).value||' ENABLE NOVALIDATE');
    END LOOP;
    xl.end_action;
  END enable_disabled_fks;
  
  
  PROCEDURE drop_partitions
  (
    p_table_list  IN VARCHAR2,  -- comma-separated list of tables, starting with "children" tables
    p_up_to       IN VARCHAR2   -- upper limit (non-inclusive)
  ) IS
    tab_fks   tab_name_values;
  BEGIN
    xl.open_log('DROP PARTITIONS', 'P_TABLE_LIST='||p_table_list||', P_UP_TO='||p_up_to, 1, $$PLSQL_UNIT);

    set_session_params;
    mb_before := get_space_usage(gv_schema);
    
    FOR r IN
    (
      SELECT TRIM(COLUMN_VALUE) table_name
      FROM TABLE(split_string(p_table_list))
    )
    LOOP
      disable_referencing_fks(r.table_name);
      
      xl.begin_action('Dropping partitions from table', gv_schema||'.'||r.table_name, 1, $$PLSQL_UNIT);
      FOR p IN
      (
        SELECT
          q.*, c.data_type,
          LEAD(partition_name) OVER(ORDER BY partition_position) next_partition
        FROM
        (
          SELECT DISTINCT
            owner, table_name, partition_name, partition_position, part_high_value,
            partitioning_type, partitioned_by, part_key_column_cnt
          FROM v_table_partition_info
          WHERE owner = gv_schema 
          AND table_name = r.table_name
        ) q
        LEFT JOIN v_all_columns c
          ON c.owner = q.owner
         AND c.table_name = q.table_name
         AND c.column_name = q.partitioned_by
        ORDER BY q.partition_position
      )
      LOOP
        xl.begin_action('Processing partition', p.partition_name, 1, $$PLSQL_UNIT);
        
        IF p.part_key_column_cnt = 0 THEN
          Raise_Application_Error(-20000, 'This table is not partitioned!');
        ELSIF p.part_key_column_cnt > 1 THEN
          Raise_Application_Error(-20000, 'Partition KEY consists of more than one column: '||p.partitioned_by||'!');
        END IF;
        
        IF p.partitioning_type NOT IN ('RANGE','LIST') THEN
          Raise_Application_Error(-20000, 'Wrong partitioning type: '||p.partitioning_type||'!');
        END IF;
        
        IF p.next_partition IS NULL THEN
          xl.end_action('This is the last partition. We cannot drop it.');
          EXIT;
        END IF;
        
        IF p.data_type = 'INTEGER' OR p.data_type LIKE 'NUMBER%' THEN
          IF eval_number(p.part_high_value) > eval_number(p_up_to)
            OR p.partitioning_type = 'LIST' AND eval_number(p.part_high_value) = eval_number(p_up_to)
          THEN
            xl.end_action('Reached the "Up To" limit');
            EXIT;
          END IF;
        ELSIF p.data_type = 'DATE' OR p.data_type LIKE 'TIMESTAMP%' THEN
          IF eval_date(p.part_high_value) > eval_date(p_up_to)
            OR p.partitioning_type = 'LIST' AND eval_date(p.part_high_value) = eval_date(p_up_to)
          THEN            
            xl.end_action('Reached the "Up To" limit');
            EXIT;
          END IF;
        ELSE
          Raise_Application_Error(-20000, 'Partitioning column '||p.partitioned_by||' is of wrong data type: '||p.data_type||'!');
        END IF;
        
        exec_sql('ALTER TABLE '||r.table_name||' DROP PARTITION '||p.partition_name);
        
        xl.end_action; -- Processing partition
      END LOOP;
      xl.end_action; -- Dropping partitions from table
      
      enable_disabled_fks;
    END LOOP;
    
    mb_after := get_space_usage(gv_schema);
    mb_diff := mb_before - mb_after;
    
    xl.close_log('Successfully completed. Freed space: '||mb_diff||' MB');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END;
  
  
  PROCEDURE drop_subpartitions
  (
    p_table_list  IN VARCHAR2,  -- comma-separated list of tables, starting with "children" tables
    p_up_to       IN VARCHAR2   -- upper limit (non-inclusive)
  ) IS
    
  BEGIN
    xl.open_log('DROP_SUBPARTITIONS', 'P_TABLE_LIST='||p_table_list||', P_UP_TO='||p_up_to, 1, $$PLSQL_UNIT);

    set_session_params;
    mb_before := get_space_usage(gv_schema);
    
    FOR r IN
    (
      SELECT TRIM(COLUMN_VALUE) table_name
      FROM TABLE(split_string(p_table_list))
    )
    LOOP
      xl.begin_action('Processing table', gv_schema||'.'||r.table_name, 1, $$PLSQL_UNIT);
      
      disable_referencing_fks(r.table_name);
      
      FOR p IN
      (
        SELECT partition_name
        FROM all_tab_partitions
        WHERE table_owner = gv_schema
        AND table_name = r.table_name
        ORDER BY partition_position
      )
      LOOP
        xl.begin_action('Dropping subpartitions from partition', p.partition_name, 1, $$PLSQL_UNIT);
        
        FOR sp IN
        (
          SELECT
            v.owner, v.table_name,
            v.subpartitioning_type, v.subpartitioned_by, v.subpart_key_column_cnt,
            v.subpartition_name, v.subpartition_position, v.subpart_high_value,
            c.data_type,
            LEAD(subpartition_name) OVER(ORDER BY subpartition_position) next_subpartition
          FROM v_table_partition_info           v
          LEFT JOIN v_all_columns               c
            ON c.owner = v.owner
           AND c.table_name = v.table_name
           AND c.column_name = v.subpartitioned_by
          WHERE v.owner = gv_schema AND v.table_name = r.table_name AND v.partition_name = p.partition_name
          ORDER BY v.subpartition_position
        )
        LOOP
          xl.begin_action('Processing subpartition', sp.subpartition_name, 1, $$PLSQL_UNIT);
          
          IF sp.subpart_key_column_cnt = 0 THEN
            Raise_Application_Error(-20000, 'This table is not sub-partitioned!');
          ELSIF sp.subpart_key_column_cnt > 1 THEN
            Raise_Application_Error(-20000, 'Subpartition KEY consists of more than one column: '||sp.subpartitioned_by||'!');
          END IF;
          
          IF sp.subpartitioning_type NOT IN ('RANGE','LIST') THEN
            Raise_Application_Error(-20000, 'Wrong subpartitioning type: '||sp.subpartitioning_type||'!');
          END IF;
          
          IF sp.next_subpartition IS NULL THEN
            xl.end_action('This is the last subpartition. We cannot drop it.');
            EXIT;
          END IF;
          
          IF sp.data_type = 'INTEGER' OR sp.data_type LIKE 'NUMBER%' THEN
            IF eval_number(sp.subpart_high_value) > eval_number(p_up_to)
              OR sp.subpartitioning_type = 'LIST' AND eval_number(sp.subpart_high_value) = eval_number(p_up_to)
            THEN
              xl.end_action('Reached the "Up To" limit');
              EXIT;
            END IF;
          ELSIF sp.data_type = 'DATE' OR sp.data_type LIKE 'TIMESTAMP%' THEN
            IF eval_date(sp.subpart_high_value) > eval_date(p_up_to)
              OR sp.subpartitioning_type = 'LIST' AND eval_date(sp.subpart_high_value) = eval_date(p_up_to)
            THEN
              xl.end_action('Reached the "Up To" limit');
              EXIT;
            END IF;
          ELSE
            Raise_Application_Error(-20000, 'Subpartitioning column '||sp.subpartitioned_by||' is of wrong data type: '||sp.data_type||'!');
          END IF;
        
          exec_sql('ALTER TABLE '||r.table_name||' DROP SUBPARTITION '||sp.subpartition_name);
        
          xl.end_action; -- Processing subpartition
        END LOOP;
        
        xl.end_action; -- Dropping subpartitions from partition
      END LOOP;
     
      enable_disabled_fks;
      
      xl.end_action; -- Processing table
    END LOOP;
    
    mb_after := get_space_usage(gv_schema);
    mb_diff := mb_before - mb_after;
    
    xl.close_log('Successfully completed. Freed space: '||mb_diff||' MB');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END drop_subpartitions;
  
  
  PROCEDURE compress_data
  (
    p_condition         IN VARCHAR2,-- for example: 'WHERE table_name=''MEMBERHEALTHSTATE_HIST'' AND high_value BETWEEN ''01-JAN-21'' AND ''31-DEC-22''';
    p_compress_type     IN VARCHAR2, -- for example: 'NOCOMPRESS', 'BASIC', 'OLTP', 'QUERY HIGH', etc.
    p_update_indexes    IN CHAR DEFAULT 'Y',
    p_deallocate_unused IN CHAR DEFAULT 'Y',
    p_tablespace        IN VARCHAR2 DEFAULT NULL,
    p_gather_stats      IN CHAR DEFAULT 'N'
  ) IS
    rcur            SYS_REFCURSOR;
    v_table_name    VARCHAR2(30) := 'N/A';
    v_part_name     VARCHAR2(30) := 'N/A';
    v_full_name     VARCHAR2(100);
    v_compress      VARCHAR2(30);
    v_update_idx    VARCHAR2(30);
    
    PROCEDURE gather_stat IS
    BEGIN
      IF p_gather_stats = 'Y' AND v_table_name <> 'N/A' THEN
        xl.begin_action('Analyzing table '||v_table_name||' partition '||v_part_name);
        analyze_table_partition(v_table_name, v_part_name); 
        xl.end_action;
      END IF;
    END;
    
  BEGIN
    xl.open_log
    (
      'COMPRESS_DATA',
      'Condition: '||p_condition||'; Compress type: '||p_compress_type||'; Update Indexes: '||p_update_indexes||'; Gather stats: '||p_gather_stats,
      1, $$PLSQL_UNIT
    );
    set_session_params;
    
    mb_before := get_space_usage(gv_schema);
    
    v_compress := CASE p_compress_type
      WHEN 'NOCOMPRESS' THEN ' NOCOMPRESS'
      WHEN 'BASIC' THEN ' COMPRESS BASIC'
      ELSE ' COMPRESS FOR '||p_compress_type
    END;
    
    v_update_idx := CASE p_update_indexes WHEN 'Y' THEN ' UPDATE INDEXES' END;  
    
    prepare_qry(p_condition);
    
    xl.begin_action('Opening cursor for', gv_sql);
    OPEN rcur FOR gv_sql;
    xl.end_action;

    LOOP
      FETCH rcur INTO rec;
      EXIT WHEN rcur%NOTFOUND;
      
      CASE WHEN rec.partition_name IS NULL THEN
        exec_sql
        (
          'ALTER TABLE '||rec.table_name||' MOVE '||v_compress||' PARALLEL 32'
        );
        
        IF p_deallocate_unused = 'Y' THEN
          deallocate_unused(rec.table_name);
        END IF;
          
      WHEN rec.subpartition_name IS NULL THEN 
        exec_sql
        (
          'ALTER TABLE '||rec.table_name||' MOVE PARTITION '||rec.partition_name||' '||
          v_compress||v_update_idx||' PARALLEL 32'
        );
        
        IF p_deallocate_unused = 'Y' THEN
          deallocate_unused(rec.table_name, rec.partition_name);
        END IF;
      ELSE
        exec_sql('ALTER TABLE '||v_table_name||' MODIFY PARTITION '||v_part_name||v_compress);
      END CASE;
      
      IF rec.subpartition_name IS NOT NULL THEN
        exec_sql
        (
          'ALTER TABLE '||v_table_name||' MOVE SUBPARTITION '||rec.subpartition_name||'
          '||v_compress||v_update_idx||' PARALLEL 32'
        );
        
        IF p_deallocate_unused = 'Y' THEN
          deallocate_unused(v_table_name, v_part_name, rec.subpartition_name);
        END IF;
      END IF;
    END LOOP;
    
    CLOSE rcur;
    
    gather_stat;
    
    mb_after := get_space_usage(gv_schema);
    mb_diff := mb_before - mb_after;
    
    xl.close_log('Successfully completed. Freed space: '||mb_diff||' MB');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END compress_data;
  
  
  PROCEDURE truncate_tables
  (
    p_table_list    IN VARCHAR2,
    p_drop_storage  IN CHAR DEFAULT 'ALL',
    p_cascade       IN CHAR DEFAULT 'N'
  ) IS
  BEGIN
    xl.open_log('TRUNCATE_TABLES', p_table_list, 1, $$PLSQL_UNIT);

    set_session_params;
    mb_before := get_space_usage(gv_schema);
    
    FOR r IN
    (
      SELECT TRIM(COLUMN_VALUE) table_name
      FROM TABLE(split_string(p_table_list))
    )
    LOOP
      exec_sql
      (
        'TRUNCATE TABLE '||r.table_name||
        CASE p_drop_storage WHEN 'Y' THEN ' DROP STORAGE' WHEN 'ALL' THEN ' DROP ALL STORAGE' ELSE ' REUSE STORAGE' END ||
        CASE p_cascade WHEN 'Y' THEN ' CASCADE' END
      );
    END LOOP;
     
    mb_after := get_space_usage(gv_schema);
    mb_diff := mb_before - mb_after;
    
    xl.close_log('Successfully completed. Freed space: '||mb_diff||' MB');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END;
  
  
  PROCEDURE deallocate_unused_space -- to reclaim unused disk space
  (
    p_condition       IN VARCHAR2 -- for example: 'WHERE table_name=''MEMBERHEALTHSTATE_HIST'' AND eval_date(high_value) BETWEEN DATE ''2021-01-01'' AND DATE ''2022-12-31'''
  ) IS
    rcur          SYS_REFCURSOR;
  BEGIN
    xl.open_log('DEALLOCATE_UNUSED_SPACE', 'Condition: '||p_condition, 1, $$PLSQL_UNIT);

    set_session_params;
    mb_before := get_space_usage(gv_schema);
    
    prepare_qry(p_condition);

    xl.begin_action('Opening cursor for', gv_sql);
    OPEN rcur FOR gv_sql;
    xl.end_action;
    
    LOOP
      FETCH rcur INTO rec;
      EXIT WHEN rcur%NOTFOUND;
      
      CASE WHEN rec.partition_name IS NULL THEN
        deallocate_unused(rec.table_name);
      WHEN rec.subpartition_name IS NULL THEN 
        deallocate_unused(rec.table_name, rec.partition_name);
      ELSE
        deallocate_unused(rec.table_name, rec.partition_name, rec.subpartition_name);
      END CASE;
    END LOOP;
    
    CLOSE rcur;
    
    mb_after := get_space_usage(gv_schema);
    mb_diff := mb_before - mb_after;
    
    xl.close_log('Successfully completed. Freed space: '||mb_diff||' MB');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END;


  -- Procedure to re-create indexes using "COMPRESS" option.
  PROCEDURE compress_indexes
  (
    p_table_list  IN VARCHAR2 DEFAULT NULL, -- comma-separated list of tables
    p_index_list  IN VARCHAR2 DEFAULT NULL, -- comma-separated list of indexes
    p_force       IN CHAR DEFAULT 'N', -- if 'Y' then the indexes will be rebuilt even if their compression is already enabled
    p_tablespace  IN VARCHAR2 DEFAULT NULL -- tablespace to place new indexes into
  ) IS
    no_such_index EXCEPTION;
    PRAGMA EXCEPTION_INIT(no_such_index, -1418);
    
  BEGIN
    xl.open_log('COMPRESS_INDEXES', 'P_TABLE_LIST='||p_table_list||'; P_INDEX_LIST='||p_index_list, 1, $$PLSQL_UNIT);
    
    IF p_table_list IS NULL AND p_index_list IS NULL THEN
      Raise_Application_Error(-20000, 'Either the list of tables or the list of indexes should be specified!');
    END IF;
    
    set_session_params;
    mb_before := get_space_usage(gv_schema);
    
    FOR r IN
    (
      SELECT
        table_name, index_name, uniqueness, 
        constraint_name, constraint_type, 
        compression, ind_columns, ind_col_cnt,
        partitioning_type,
        MIN(tablespace_name) KEEP(DENSE_RANK FIRST ORDER BY partition_position) tablespace_name 
      FROM v_index_partition_info
      WHERE index_owner = gv_schema
      AND (p_table_list IS NULL OR table_name IN (SELECT COLUMN_VALUE FROM TABLE(split_string(p_table_list))))
      AND (p_index_list IS NULL OR index_name IN (SELECT COLUMN_VALUE FROM TABLE(split_string(p_index_list))))
      AND (compression = 'DISABLED' OR p_force = 'Y')
      AND ind_col_cnt > 1
      AND ind_columns NOT LIKE '%SYS%$' -- no function-based indexes
      GROUP BY table_name, index_name, uniqueness, constraint_name, constraint_type, compression, ind_columns, ind_col_cnt, partitioning_type, tablespace_name
      ORDER BY table_name, index_name
    )
    LOOP
      xl.begin_action('Compressing index', r.index_name);
      
      IF r.constraint_name IS NOT NULL THEN
        exec_sql('ALTER TABLE '||r.table_name||' DISABLE CONSTRAINT '||r.constraint_name);
      END IF;
      
      BEGIN
        exec_sql('DROP INDEX '||r.index_name);
        
        exec_sql
        (
          'CREATE'||CASE r.uniqueness WHEN 'UNIQUE' THEN ' UNIQUE' END ||' INDEX '||
          r.index_name||' ON '||r.table_name||'('||r.ind_columns||') 
          TABLESPACE '||NVL(p_tablespace, r.tablespace_name)||CASE WHEN r.partitioning_type IS NOT NULL THEN ' LOCAL' END ||' COMPRESS PARALLEL 32'
        );
        
        IF r.constraint_name IS NOT NULL THEN
          exec_sql('ALTER TABLE '||r.table_name||' ENABLE CONSTRAINT '||r.constraint_name);
        END IF;
        
      EXCEPTION
       WHEN no_such_index THEN
        exec_sql('ALTER TABLE '||r.table_name||' DROP CONSTRAINT '||r.constraint_name);
        
        exec_sql
        (
          'CREATE'||CASE r.uniqueness WHEN 'UNIQUE' THEN ' UNIQUE' END ||' INDEX '||
          r.index_name||' ON '||r.table_name||'('||r.ind_columns||') 
          TABLESPACE  LOCAL COMPRESS PARALLEL 32'
        );
        
        exec_sql
        (
          'ALTER TABLE '||r.table_name||' ADD CONSTRAINT '||r.constraint_name ||
          CASE r.constraint_type WHEN 'P' THEN ' PRIMARY KEY' ELSE ' UNIQUE' END ||
          '('||r.ind_columns||') USING INDEX '||r.index_name
        );
      END;
      
      exec_sql('ALTER INDEX '||r.index_name||' NOPARALLEL');
      
      xl.end_action;
    END LOOP;
    
    mb_after := get_space_usage(gv_schema);
    mb_diff := mb_before - mb_after;
    
    xl.close_log('Successfully completed. Freed space: '||mb_diff||' MB');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END compress_indexes;
  
  
  -- This public procedure marks Index Partitions as "UNUSABLE" 
  -- making Oracle remove the corresponding segments from the database 
  PROCEDURE disable_index_partitions
  (
    p_condition IN VARCHAR2,
    p_comment   IN VARCHAR2 DEFAULT NULL
  ) IS
    rcur          SYS_REFCURSOR;
    rec           v_index_partition_info%ROWTYPE;
  BEGIN
    xl.open_log('DISABLE_INDEX_PARTITIONS', NVL(p_comment, p_condition), 1, $$PLSQL_UNIT);
    
    set_session_params;
    mb_before := get_space_usage(gv_schema);
    
    gv_sql := 'SELECT * FROM v_index_partition_info '||p_condition||'
    AND index_owner = '''||gv_schema||'''
    AND (subpart_segm_created = ''YES'' OR part_segm_created = ''YES'') 
    ORDER BY table_name, index_name, partition_position, subpartition_position';
    
    xl.begin_action('Opening cursor for', gv_sql);
    OPEN rcur FOR gv_sql;
    xl.end_action;
    
    LOOP
      FETCH rcur INTO rec;
      EXIT WHEN rcur%NOTFOUND;
      
      exec_sql
      (
        'ALTER INDEX '||rec.index_name||' MODIFY '||
        CASE WHEN rec.subpartition_name IS NOT NULL THEN 'SUB' END || 'PARTITION '||
        NVL(rec.subpartition_name, rec.partition_name) || ' UNUSABLE'
      );
    END LOOP;
    CLOSE rcur;
    
    mb_after := get_space_usage(gv_schema);
    mb_diff := mb_before - mb_after;
    
    xl.close_log('Successfully completed. Freed space: '||mb_diff||' MB');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END disable_index_partitions;


  -- This procedure rebuilds Index Partitions/Sub-partitions 
  PROCEDURE enable_index_partitions
  (
    p_condition IN VARCHAR2,
    p_comment   IN VARCHAR2 DEFAULT NULL
  ) IS
    rcur          SYS_REFCURSOR;
    rec           v_index_partition_info%ROWTYPE;
  BEGIN
    xl.open_log('ENABLE_INDEX_PARTITIONS', NVL(p_comment, p_condition), 1, $$PLSQL_UNIT);
    
    set_session_params;
    mb_before := get_space_usage(gv_schema);
    
    gv_sql := 'SELECT * FROM v_index_partition_info '||p_condition||'
    AND owner = '''||gv_schema||'''
    AND 
    (
      subpartition_name IS NOT NULL AND subpart_segm_created = ''NO''
      OR
      subpartition_name IS NULL AND part_segm_created = ''NO''
    ) 
    ORDER BY table_name, index_name, partition_name, subpartition_name';
    
    xl.begin_action('Opening cursor for', gv_sql);
    OPEN rcur FOR gv_sql;
    xl.end_action;
    
    LOOP
      FETCH rcur INTO rec;
      EXIT WHEN rcur%NOTFOUND;
      
      exec_sql
      (
        'ALTER INDEX '||rec.index_name||' REBUILD '||
        CASE WHEN rec.subpartition_name IS NOT NULL THEN 'SUB' END || 'PARTITION '||
        NVL(rec.subpartition_name, rec.partition_name)
      );
    END LOOP;
    
    CLOSE rcur;

    mb_after := get_space_usage(gv_schema);
    mb_diff := mb_after - mb_before;
    
    xl.close_log('Success. Used space: '||mb_diff||' MB');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END enable_index_partitions;
  
  
  -- This public procedure gathers statistics on Tables, their Partitions and Subpartitions
  PROCEDURE gather_stats
  (
    p_condition         IN VARCHAR2,
    p_degree            IN PLS_INTEGER DEFAULT NULL,
    p_granularity       IN VARCHAR2 DEFAULT NULL,
    p_estimate_pct      IN NUMBER DEFAULT NULL,
    p_cascade           IN BOOLEAN DEFAULT NULL,
    p_method_opt        IN VARCHAR2 DEFAULT NULL
  ) IS
    TYPE typ_rec IS RECORD(table_name VARCHAR2(128), partition_name VARCHAR2(30), partition_position NUMBER);
    rec           typ_rec;
    rcur          SYS_REFCURSOR;
    v_full_name   VARCHAR2(100);
    v_lock        VARCHAR2(128);
    n_locked      PLS_INTEGER;
    ts_start      TIMESTAMP;
    ts_last       TIMESTAMP;
  BEGIN
    ts_start := SYSTIMESTAMP;
    xl.open_log('GATHER_STATS', p_condition);
    
    set_session_params;
    gv_sql := 'SELECT DISTINCT table_name, partition_name, partition_position FROM v_table_partition_info '||
     p_condition || ' AND owner = '''||gv_schema||''' ORDER BY table_name, partition_position';
    
    xl.begin_action('Opening cursor for query', gv_sql);
    OPEN rcur FOR gv_sql;
    xl.end_action; 
    
    LOOP
      FETCH rcur INTO rec;
      EXIT WHEN rcur%NOTFOUND;
      
      v_full_name := rec.table_name || CASE WHEN rec.partition_name IS NOT NULL THEN ' PARTITION('||rec.partition_name||')' END; 
      
      xl.begin_action('Analyzing table/partition', v_full_name);
      
      DBMS_LOCK.ALLOCATE_UNIQUE(v_full_name, v_lock);
      n_locked := DBMS_LOCK.REQUEST(lockhandle => v_lock, timeout => 0);
        
      IF n_locked IN (0, 4) THEN -- Successfully locked
        SELECT MIN(COALESCE(subpart_last_analyzed, part_last_analyzed, table_last_analyzed))
        INTO ts_last
        FROM v_table_partition_info
        WHERE owner = gv_schema
        AND table_name = rec.table_name
        AND NVL(partition_name, 'N/A') = NVL(rec.partition_name, 'N/A');
          
        IF ts_last > ts_start THEN
          xl.end_action('This table/partition has been already analyzed by another session, skipping ...');
        ELSE
          analyze_table_partition
          (
            p_table_name => rec.table_name,
            p_partition_name => rec.partition_name,
            p_degree => p_degree,
            p_granularity => p_granularity,
            p_estimate_pct => p_estimate_pct,
            p_cascade => p_cascade,
            p_method_opt => p_method_opt
          );
          xl.end_action;
        END IF;
        
        n_locked := DBMS_LOCK.RELEASE(v_lock);
        IF n_locked > 0 THEN
          xl.begin_action('Releasing lock on '||v_full_name);
          Raise_Application_Error(-20000, 'DBMS_LOCK.RELEASE returned unexpected result: '||n_locked);
        END IF;
        
      ELSIF n_locked = 1 THEN
        xl.end_action('Another session has locked this table/partition, skipping ...');
      ELSE
        Raise_Application_Error(-20000, 'DBMS_LOCK.REQUEST returned unexpected result: '||n_locked);
      END IF;
    END LOOP;
    
    xl.close_log('Success');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END;
  
  
  PROCEDURE set_stats_gather_prefs
  (
    p_pref_name   IN VARCHAR2,
    p_value       IN VARCHAR2,
    p_table_name  IN VARCHAR2 DEFAULT NULL
  ) IS
  BEGIN
    set_session_params;
    
    IF p_table_name IS NULL THEN
      dbms_stats.set_schema_prefs(gv_schema, p_pref_name, p_value);
    ELSE
      dbms_stats.set_table_prefs(gv_schema, p_table_name, p_pref_name, p_value);
    END IF;
  END;
END pkg_db_maintenance_api;
/
