CREATE OR REPLACE PACKAGE BODY pkg_etl_utils AS
/*
  =================================================================================================
  Package ETL_UTILS contains procedures for performing data transformation operations:
  add data to or delete data from target tables based on the source tables/views/queries.

  It was developed by Oleg Khaykin: 1-201-625-3161. OlegKhaykin@gmail.com. 
  Your are allowed to use and change it as you wish.
  =================================================================================================
  
  History of changes (newest to oldest):
  ------------------------------------------------------------------------------
  29-JUL-2024, OK: uploaded a new version.
  =================================================================================================
*/

  remote_object EXCEPTION;
  PRAGMA EXCEPTION_INIT(remote_object, -20001);
  
  b_debug       BOOLEAN := FALSE;
  
  PROCEDURE set_debug IS
  BEGIN
    b_debug := CASE WHEN UPPER(NVL(SYS_CONTEXT('CTX_LOCAL_ETL','DEBUG'), 'FALSE')) = 'TRUE' THEN TRUE ELSE FALSE END;
  END set_debug;
 
  -- Format a numeric string nicely
  PROCEDURE int_str(p_int IN INTEGER) IS
  BEGIN
    RETURN LTRIM(TO_CHAR(p_int, '999G999G999G999G999'));
  END int_str;
  
  -- Procedure PARSE_NAME splits the given name into 3 pieces:
  -- 1)schema, 2)table/view name and 3)DB_link
  PROCEDURE parse_name
  (
    p_name    IN  VARCHAR2,
    p_schema  OUT VARCHAR2,
    p_table   OUT VARCHAR2,
    p_db_link OUT VARCHAR2
  ) IS
    v_name    VARCHAR2(92);
    l         PLS_INTEGER;
    n         PLS_INTEGER;
    m         PLS_INTEGER;
  BEGIN
    xl.begin_action('PARSE_NAME', 'P_NAME='||p_name, 10, $$PLSQL_UNTI);
    v_name := UPPER(p_name);
    n := INSTR(v_name, '.');
    m := INSTR(v_name, '@');
    l := LENGTH(v_name);
 
    p_schema := CASE WHEN n>0 THEN SUBSTR(v_name, 1, n-1) END;
    p_table := SUBSTR(v_name, n+1, CASE WHEN m>0 THEN m-n-1 ELSE l END);
    p_db_link := CASE WHEN m>0 THEN SUBSTR(v_name, m+1) END;
    
    xl.end_action('P_SCHEMA: '||p_schema||', P_TABLE: '||p_table||', P_DB_LINK: '||p_db_link));
  END parse_name;
  
  
  -- Procedure FIND_TABLE finds the actual SCHEMA.NAME 
  -- for the given SCHEMA.NAME, which can be a synonym
  PROCEDURE find_table
  (
    p_schema  IN OUT VARCHAR2,
    p_table   IN OUT VARCHAR2
  ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
    v db link   VARCHAR2(30);
    v_obj_type  VARCHAR2(30);
    n cnt       PLS_INTEGER;
  BEGIN
    xl.begin_action('FIND_TABLE','P_SCHEMA='||p_schema||', P_TABLE='||p_table, 10, $$PLSQL_UNIT);
    
    SELECT COUNT(1) INTO n_cnt FROM tmp_all_synonyms;  
    IF n_cnt = 0 THEN
      xl.begin_action('Populating TMP_ALL_SYNONYMS', 'Started', 10, $$PLSQL_UNIT||'.FIND_TABLE');
      INSERT INTO tmp_all_synonyms(owner, synonym_name, table_owner, table_name, db_link)
      SELECT owner, synonym_name, table_owner, table_name, db_link
      FROM
      (
        SELECT
          owner, synonym_name, table_owner, table_name, db_link,
          ROW NUMBER() OVER(PARTITION BY owner, synonym_name ORDER BY origin_con_id DESC) rn
        FROM all_synonyms
      )
      WHERE rn = 1;
      n_cnt := SQL&ROWCOUNT;
      xl.end_action(n_cnt||' rows inserted');
      COMMIT;
    END IF;
    
    LOOP
      SELECT object_type, table_owner, table_name, db_link
      INTO v_obj_type, p_schema, p_table, v_db_link
      FROM
      (
        SELECT
          object_type, table_owner, table_name, db_link,
          ROW_NUMBER() OVER(PARTITION BY object_name ORDER BY DECODE(object_type, 'SYNONYM', 2, 1), DECODE (owner, 'PUBLIC', 2, 1)) rnum
        FROM
        (
          SELECT
            object_type,
            owner,
            object_name,
            owner AS table_owner,
            object name AS table_name,
            NULL AS db_link
          FROM all_objects
          WHERE object_type IN ('TABLE', 'VIEW') AND object_name = UPPER(p_table)
          AND owner = NVL(p_schema, SYS_CONTEXT ('USERENV', 'CURRENT_SCHEMA'))
         UNION ALL
          SELECT
            'SYNONYM' AS object_type,
            owner,
            synonym_name AS object_name,
            table_owner,
            table_name,
            db_link
          FROM tmp all synonyms
          WHERE synonym name = UPPER(p_table)
          AND owner IN (NVL(p_schema, SYS_CONTEXT ('USERENV', 'CURRENT_SCHEMA')), 'PUBLIC')
        )
      )
      WHERE rnum = 1;
      
      IF v_db_link IS NOT NULL THEN
        Raise_Application_Error(-20001, 'Remote object: '|| CASE WHEN p_schema IS NOT NULL THEN p_schema||'.' END ||p_table||' '||v_db_link)
      END IF;
      
      EXIT WHEN v_obj_type <> 'SYNONYM';
    END LOOP;
    
    xl.end_action('P_SCHEMA: '||p_schema||', P_TABLE: '||p_table);
  EXCEPTION
   WHEN NO DATA FOUND THEN
    Raise_Application_Error(-20000, 'Unknown table/view: '||p_table);
  END find_table;
    
    
  -- Procedure RESOLVE_NAME resolves the given table/view/synonym name
  -- into a complete SCHEMA.NAME description of the underlying table/view
  PROCEDURE resolve_name
  (
    p_name    IN VARCHAR2,
    p_schema  OUT VARCHAR2,
    p_table   OUT VARCHAR2
  ) IS
    v_db_link VARCHAR2 (100) ;
  BEGIN
    xl.open_log('RESOLVE_NAME', 'P_NAME='||p_name, 10, $$PLSQL_UNIT);
    
    parse_name(p_name, p_schema, p_table, v_db_link);

    IF v_db_link IS NOT NULL THEN
      Raise_Application_Error (-20001, 'Remote object: '|| CASE WHEN p_schema IS NOT NULL THEN p_schema||'.' END || p_table||' '||v_db_link);
    END IF;

    find_table(p_schema, p_table);
    p_schema := NVL(p_schema, SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'));
    
    xl.close_log('Resolved: '||p_schema||'.'||p_table);
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE) ;
    RAISE;
  END resolve_name;
  

  -- Function GET_KEY_COL_LIST returns a comma-separated list of the columns
  -- that constitute the given table's (P_TABLE) key (P_KEY).
  -- By default - i.e. if P_KEY is NULL - describes the table PK.
  FUNCTION get_key_col_list(p_table IN VARCHAR2, p_key IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 IS
    v_schema  VARCHAR2(30);
    v_tname   VARCHAR2(128);
    v_ret     VARCHAR2 (1000);
  BEGIN
    xl.begin_action('GET_KEY_COL_LIST', 'P_TABLE='||p_table||', P_KEY='||p_key, 10, $$PLSQL_UNIT);

    resolve_name (p_table, v_schema, v_tname) ;

    SELECT concat_v2_set
    (
      CURSOR
      (
        SELECT cc.column_name
        FROM all_constraints c
        JOIN all_cons columns cc ON cc.owner = c.owner AND cc.constraint_name = c.constraint_name
        WHERE c.owner = v_schema AND c.table_name = v tname
        AND
        (
          c.constraint_type = 'P' AND p_key IS NULL
          OR
          c.constraint_name = p_key
        )
        ORDER BY cc.position
      )
    ) INTO v_ret FROM dual;

    xl.end_action;
    RETURN ret;
  END get_key_col_list;
  
  
  PROCEDURE close_db_link(p_db_link IN VARCHAR2) IS
    e_db_link_not_open EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_db_link_not_open, -2081);
  BEGIN
    xl.begin_action('CLOSE_DB_LINK', p_db_link, 10, $$PLSQL_UNIT) ;
    dbms_session.close_database_link(p_db_link) ;
    xl.end_action;
  EXCEPTION
   WHEN e_db_link_not_open THEN
    x1.end_action (SQLERRM) ;
  END close_db_link;
   
   
  -- Please, see the description of this procedure in the package specification
  PROCEDURE add_data
  (
    p_operation       IN VARCHAR2, -- 'INSERT', 'UPDATE', 'MERGE' or 'REPLACE'
    p_target          IN VARCHAR2, -- target table to add rows to
    p_source          IN VARCHAR2, -- source table, view or query
    p_where           IN VARCHAR2 DEFAULT NULL, -- optional WHERE condition to apply to the source
    p_hint            IN VARCHAR2 DEFAULT NULL, -- optional hint for the source query
    p_match_cols      IN VARCHAR2 DEFAULT NULL, -- see the procedure description in the package specification
    p_check_changed   IN VARCHAR2 DEFAULT NULL, -- see the procedure description in the package specification
    p_generate        IN VARCHAR2 DEFAULT NULL, -- see the procedure description in the package specification
    p_delete          IN VARCHAR2 DEFAULT NULL, -- see the procedure description in the package specification
    p_versions        IN VARCHAR2 DEFAULT NULL, -- see the procedure description in the package specification
    p_commit at       IN NUMBER   DEFAULT 0,    -- see the procedure description in the package specification
    p_errtab          IN VARCHAR2 DEFAULT NULL, -- optional error log table,
    p_add_cnt         IN OUT INTEGER,           -- number of added/changed rows
    p_err_cnt         IN OUT INTEGER            -- number of errors
  ) IS
    C_MODULE          CONSTANT VARCHAR2 (128) := $$PLSQL_UNIT||'.ADD_DATA';
    v_sess_id         VARCHAR2(30) ;
    ts_start          TIMESTAMP;
    v_operation       VARCHAR2(8);
    v_source          varchar2(128);
    v_view_name       VARCHAR2(30);
    v_obj_type_name   VARCHAR2(30);
    v_tab_type_name   VARCHAR2(30);
    v_src_schema      VARCHAR2(30);
    v_src_table       VARCHAR2(128);
    v_tgt_schema      VARCHAR2(30);
    v_tgt_table       VARCHAR2(128);
    v_err_schema      VARCHAR2(30);
    v_err_table       VARCHAR2(128);
    v_match_cols      VARCHAR2(200);
    v_on_list         VARCHAR2(500);
    v_sel_cols        VARCHAR2(20000);
    v_ins_cols        VARCHAR2(20000);
    v_upd_cols        VARCHAR2(20000);
    v_upd_list        VARCHAR2(20000);
    v_changed_cond    VARCHAR2(20000);
    v_hint            VARCHAR2(100);
    v_hint2           VARCHAR2(100);
    v_gen_cols        VARCHAR2(500);
    v_gen_vals        VARCHAR2(1000);
    v_del_cond        VARCHAR2(250);
    v_del_col         VARCHAR2(30);
    v_del_val         VARCHAR2(30);
    v_active_val      VARCHAR2(30);
    v_version_col     VARCHAR2(30);
    v_since_col       VARCHAR2(30);
    v_since_expr      VARCHAR2(100);
    v until col       VARCHAR2(30) ;
    v_until expr      VARCHAR2(100);
    c until nullable  CHAR(1);
    v_src             VARCHAR2(32000);
    v_cmd             CLOB;
    v act             VARCHAR2(32000);
    n_cnt             PLS_INTEGER;
    b del notfound    BOOLEAN := FALSE;
    
    -- Procedure COLLECT METADATA gathers information about the columns of the target table and the source table/view.
    -- Gathered information is stored in TMP_COLUMN_INFO and then used in to generate DML statements.
    PROCEDURE collect_metadata IS
      C MODULE CONSTANT VARCHAR2 (128) := $$PLSQL_UNIT| | '.ADD_DATA. COLLECT_METADATA';
      PRAGMA AUTONOMOUS TRANSACTION;
    BEGIN
      COMMIT; -- to purge TMP_ALL_COLUMNS, just in case

      x1.begin_action('COLLECT_METADATA', 'Collecting and analyzing metadata', 10, $$PLSQL_UNIT||'.ADD_DATA') ;

      xl.begin_action('Collecting metadata', 'Started', 10, C_MODULE) ;
      INSERT INTO tmp_all_columns (side, owner, table_name, column_id, column_name, data_type, uk, nullable)
      SELECT 'SRC', cl.owner, cl.table_name, cl.column_id, cl.column_name, cl.data_type, 'N', 'Y'
      FROM v_all_columns cl
      WHERE cl.owner = v_src_schema AND cl.table_name = v_src_table AND cl.column_id IS NOT NULL -- invisible columns have NULL in COLUMN_ID
     UNION
      SELECT 'TGT', cl.owner, cl.table_name, cl.column_id, cl.column_name, cl.data_type, NVL2(cc.column_name, 'Y', 'N') uk, cl.nullable
      FROM v_all_columns cl
      LEFT JOIN all_constraints c
      ON c.owner = cl.owner AND c.table_name = cl.table_name
      AND c.constraint_ type = 'P'
      LEFT JOIN all_cons_columns cc
      ON cc.owner = c.owner
      AND cc.constraint_name = c.constraint_name
      AND cc.column_name = cl.column_name
      WHERE cl.owner = v_tgt_schema AND cl.table_name = v_tgt_table AND cl.column_id IS NOT NULL;
      xl.end_action;

      xl.begin_action('Setting V_INS_COLS and V_SEL_COLS', 'Started', 10, C_MODULE);
      SELECT
        concat_v2_set(CURSOR
        (
          SELECT 's.'|| tc. column_name
          FROM tmp_all_columns tc
          JOIN tmp all_columns sc ON sc.column_name = tc.column_name AND sc.side = 'SRC'
          WHERE tc.side = 'TGT'
          AND tc.column_name NOT IN (NVL(v_version_col, '$'), NVL(v_del_col, '$'))
          AND tc.column_name NOT IN
          (
            SELECT CASE WHEN COLUMN_VALUE LIKE '"$' THEN COLUMN_VALUE ELSE UPPER(COLUMN_VALUE) END
            FROM TABLE(split_string(v_gen_cols))
          )
          ORDER BY tc.column_id
        )),
        concat_v2_set(CURSOR
        (
          SELECT sc.column_name||' '|| sc.data_type
          FROM tmp_all_columns sc
          JOIN tmp_all_columns tc ON tc.column_name = sc.column_name AND tc.side = 'TGT'
          WHERE sc.side = 'SRC'
          AND sc.column_name NOT IN (NVL(v_version_col, '$'), NVL(v_del_col, '$'))
          AND sc.column_name NOT IN
          (
            SELECT CASE WHEN COLUMN_VALUE LIKE '"%' THEN COLUMN_VALUE ELSE UPPER(COLUMN_VALUE) END
            FROM TABLE(split_string(v_gen_cols))
          )
          ORDER BY tc.column_id
        ))
      INTO v_ins_cols, v_sel_cols
      FROM dual;
      
      IF v_ins_cols IS NULL THEN
        Raise_Application_Error
        (
          -20000,
          'No common columns found for the source and target tables. '1l
          'Check that you have access to both of them and they have matching columns.'
        );
      END IF;
      xl.end_action('V_INS_COLS: '||v_ins_cols||CHR(10)||'V_SEL_COLS: '||v_sel_cols);

      IF v_operation IN ('MERGE', 'UPDATE') THEN
        xl.begin_action('Setting V_MATCH_COLS', 'Started', 10, C_MODULE);
        IF p_match_cols IS NOT NULL THEN
          v match_cols := UPPER(REPLACE(p_match_cols, ' '));
        ELSE
          SELECT
            concat_v2_set(CURSOR
            (
              SELECT column_name
              FROM tmp_all_columns
              WHERE side = 'TGT' AND uk = 'Y'
              ORDER BY column id
            ))
          INTO v_match cols
          FROM dual;
        END IF;
        xl.end_action(v_match_cols);
        
        xl.begin_action('Setting V_UPD_COLS', 'Started', 10, C_MODULE) ;
        SELECT
          concat_v2_set(CURSOR
          (
            SELECT column_name FROM tmp_all_columns
            WHERE side = 'TGT' AND column name <> NVL(v_del_col, '$')
           INTERSECT
            SELECT column_name FROM tmp_all_columns
            WHERE side = 'SRC'
           MINUS
            SELECT t.COLUMN VALUE
            FROM TABLE(CAST(split_string(v_match_cols) AS tab_v256)) t
           MINUS
            SELECT t. COLUMN_VALUE
            FROM TABLE(CAST(split_string(v_gen_cols) AS tab_v256)) t
          ))
        INTO v_upd_cols
        FROM dual;
        xl.end_action(v_upd_cols) ;
        
        xl.begin_action('Setting V_UPD_LIST', 'Started', 10, C_MODULE) ;
        v upd list := REGEXP_REPLACE(v_upd_cols, '([^,]+)', 't.\1=s.\1');
        xl.end_action(v_upd_list);
        
        CASE
          WHEN v match cols IS NULL THEN
            Raise_Application_Error(-20000, 'The target table has no Primary Key. You must use the parameter P_MATCH_COLS.');
          WHEN v_match_cols = 'ROWID' THEN
            IF p_check_changed IS NOT NULL THEN
              Raise_Application_Error
              (
                -20000, 'If the target table is pre-joined in the source view/query 'll
                'then please implement the change checking logic there '1l
                'and do not use the P_CHECK_CHANGED parameter.'
              );
            END IF;

            IF b_del_notfound THEN
              xl.begin_action ('Checking that the source has the column ETL$SRC_INDICATOR', 'Started', 10, C_MODULE) ;
              SELECT COUNT(1) INTO n_cnt
              FROM tmp all columns
              WHERE side = 'SRC' AND column_name = 'ETL$SRC_INDICATOR';

              IF n cnt = 0 THEN
                Raise_Application_Error
                (
                  -20000, 'When the target table is pre-joined in the source view/query and the NOTFOUND '1 I
                  'delete condition is used then the source must have a column ETL$SRC_INDICATOR. '1I
                  'Please see ADD_DATA description in the package PKG_ETL_UTILS specification.'
                );
              END IF;
              xl.end_action;
            END IF;
            
            v_on_list := 't.ROWID = s.row_id';

          ELSE -- matching on regular columns, not on ROWID
            xl.begin_action('Setting V_ON_LIST', 'Started', 10, C_MODULE) ;
            SELECT
              concat_v2_set
              (
                CURSOR
                (
                  SELECT
                    CASE t.nullable
                      WHEN 'N' THEN 't.'||t.column_name||'=s.'||column_name
                    ELSE CASE
                      WHEN t.data_type LIKE '%CHAR%' THEN
                        'NVL(t.'||t.column_name||', ''$$N/A$$'') = NVL(s.'||t.column_name||', ''$$N/A$$'')'
                      WHEN t.data_type = 'DATE' THEN
                        'NVL(t.'||t.column_name||', DATE ''0001-01-01'') = NVL(s.'||t.column_name||', DATE ''0001-01-01'')'
                      WHEN t.data_type LIKE 'TIME%' THEN
                        'NVL(t.'||t.column_name||', TIMESTAMP ''0001-01-01 00:00:00'') = NVL(s.'||t.column_name||', TIMESTAMP ''0001-01-01 00:00:00'')'
                      ELSE
                        'NVL(t.'||t.column_name||', -101010101) = NVL(s.'||t.column_name||', -101010101)'
                      END
                    END
                  FROM tmp_all_columns t
                  JOIN TABLE(split_string(v_match_cols)) mc ON mc.COLUMN_VALUE = t.column_name
                  WHERE t.side = 'TGT'
                  ORDER BY t.column_id
                ),
                ' AND '
              )
            INTO v on list FROM dual;
            xl.end_action(v_on_list);
            
            xl.begin_action('Setting V_CHANGED_COND', 'Started', 10, C_MODULE);
            v_changed_cond := NVL(TRIM(UPPER(p_check_changed)), 'ALL');
            CASE
              WHEN v_changed_cond = 'NONE' THEN
                v_changed_cond := NULL;
              WHEN v_changed_cond NOT LIKE 'EXCEPT%' THEN
                v_changed_cond := SUBSTR(REPLACE(REGEXP_REPLACE(CASE v_changed_cond WHEN 'ALL' THEN v_upd_cols ELSE v_changed_cond END, '([^, ]+)', 'OR LNNVL(t.\1=s.\1)'), ',', ' '), 4);
              ELSE -- EXCEPT:
                SELECT
                  concat_v2_set
                  (
                    CURSOR
                    (
                      SELECT 'LNNVL(t.'||column_name||'=s.'||column_name||')'
                      FROM
                      (
                        SELECT t.COLUMN VALUE AS column_name
                        FROM TABLE(CAST(split_string(v_upd_cols) AS tab_v256)) t
                       MINUS
                        SELECT t.COLUMN VALUE
                        FROM TABLE(CAST(split_string(LTRIM(REPLACE(v_changed_cond, 'EXCEPT'))) AS tab_v256)) t
                      )
                    ),
                    ' OR '
                  )
                INTO v changed_cond FROM dual;
            END CASE;
            
            IF b_del_notfound THEN
              IF v_del_col IS NOT NULL THEN
                v_changed_cond := 's.etl$src_indicator = 1 AND (('||v_changed_cond||') OR t.'||v_del_col||'='||v_del_val||') OR s.etl$src_indicator IS NULL AND t.'||v_del_col||'='||v_active_val;
              END IF;
            END IF;
            xl.end_action(v_changed_cond) ;
        END CASE; -- v_match_cols
      END IF; -- MERGE or REPLACE

      xl.begin_action ('Checking that all referenced columns actually exist', 'Started', 10, C_MODULE);
      FOR r IN
      (
        SELECT u.column_name, NVL2(ac.column_name, 'Y', 'N') exists_flag
        FROM
        (
          SELECT t.COLUMN_VALUE column_name
          FROM TABLE(tab_v256(v_del_col, v_version_col, v_since_col, v_until_col)) t
         UNION
          SELECT t.COLUMN_VALUE
          FROM TABLE(split_string(v_match_cols)) t
          WHERE t.COLUMN VALUE <> 'ROWID'
         UNION
          SELECT t.COLUMN VALUE
          FROM TABLE(split_string(v_gen_cols)) t
        ) u
        LEFT JOIN tmp_all_columns ac
          ON ac.column_name = u.column_name AND ac.side = 'TGT'
        WHERE u.column_name IS NOT NULL
      )
      LOOP
        IF r.exists_flag = 'N' THEN
          Raise_Application_Error (-20000, 'No column '||r.column_name||' in the target table!');
        END IF;
      END LOOP;
      xl.end_action;

      IF v_until_col IS NOT NULL THEN
        SELECT nullable INTO c_until_nullable
        FROM tmp_all_columns
        WHERE side = 'TGT' AND column_name = v_until_col;
      END IF;

      COMMIT; -- to finish autonomous transaction before exiting this procedure
      xl.end_action;
    END collect_metadata;
    
    PROCEDURE clean_up IS
      C_MODULE CONSTANT VARCHAR2(128) := $$PLSQL_UNIT||'.ADD_DATA.CLEAN_UP';
    BEGIN
      xl.begin_action('CLEAN_UP', 'Started', 10, $$PLSQL_UNIT||'.ADD_DATA');
      
      IF v_view_name IS NOT NULL THEN
        v_cmd := 'DROP VIEW '||v_view_name;
        xl.begin_action('Dropping view '||v_view_name, v_cmd, 1, C_MODULE) ;
        EXECUTE IMMEDIATE v_cmd;
        xl.end_action;
      END IF;
      
      IF v_tab_type_name IS NOT NULL THEN
        v_cmd := 'DROP TYPE '||v_tab_type_name;
        xl.begin_action('Dropping type '||v_tab_type_name, v_cmd, 10, C_MODULE) ;
        EXECUTE IMMEDIATE v_cmd;
        xl.end_action;
      END IF;
      
      IF v_obj_type_name IS NOT NULL THEN
        v cmd := 'DROP TYPE '||v_obj_type_name;
        xl.begin_action('Dropping type '||v_obj_type_name, v_cmd, 10, C_MODULE) ;
        EXECUTE IMMEDIATE v_cmd;
        xl.end_action;
      END IF;
      xl.end_action;
    END clean_up;
        
    FUNCTION list_param(p_name IN VARCHAR2, p_value IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
      IF p_value IS NOT NULL THEN
        RETURN p_name||'="'||p_value||'", ';
      ELSE
        RETURN NULL;
      END IF;
    END;

  BEGIN
    xl.open_log
    (
      'ADD DATA',
      RTRIM
      (
        list param('P_OPERATION', p_operation) ||
        list_param('P_TARGET', p_target) ||
        list_param('P_SOURCE', p_source) ||
        list_param('P_WHERE', p_where) ||
        list_param('P_HINT', p_hint) ||
        list param('P_MATCH_COLS', p_match_cols) ||
        list_param('P_CHECK_CHANGED', p_check_changed) ||
        list_param('P_GENERATE', p_generate) ||
        list_param('P_DELETE', p_delete) ||
        list_param('P_VERSIONS', p_versions) ||
        list_param('P_COMMIT_AT', p_commit_at) ||
        list_param('P_ERRTAB', p_errtab)
      ),
      1, $$PLSQL_UNIT
    );
    IF p_operation IS NULL OR p_target IS NULL OR p_source IS NULL THEN
      Raise_Application_Error(-20000, 'Parameter '||CASE WHEN p_operation IS NULL THEN 'P_OPERATION' WHEN p_target IS NULL THEN 'P_TARGET' ELSE 'P_SOURCE' END ||' was not specified!');
    END IF;
    
    set_debug;
    v_source := substitute_parameters(p_source);
        
    n_cnt := INSTR(p_operation, ' ');
    
    IF n_cnt = 0 THEN n_cnt := LENGTH(p_operation); END IF;
    
    v_operation := RTRIM(UPPER(SUBSTR(p_operation, 1, n_cnt)));
    hint := SUBSTR(p operation, n cnt+1);
    
    IF v_operation NOT IN ('INSERT', 'UPDATE', 'MERGE', 'REPLACE', 'TRUNCATE') THEN
      Raise_Application_Error(-20000, 'Unsupported operation: '||v_operation);
    END IF;

    v_sess_id := NVL(TO_CHAR(x1.get_current_proc_id), SYS_CONTEXT('USERENV', 'SESSIONID'));
    ts_start := SYSTIMESTAMP;

    IF v_operation IN ('INSERT', 'REPLACE') THEN
      IF p_match_cols IS NOT NULL THEN
        Raise_Application_Error(-20000, 'To avoid confusion, please do not use P_MATCH_COLS parameter together with '||v_operation||' operation.');
      END IF;

      IF p_check_changed IS NOT NULL THEN
        Raise_Application_Error (-20000, 'To avoid confusion, please do not use P_CHECK_CHANGED parameter together with '||v_operation||' operation.')
      END IF;
    ELSE
      v_match_cols := UPPER(REPLACE(p_match_cols, ' '));
    END IF;
    
    IF p_delete IS NOT NULL THEN
      IF v_operation IN ('INSERT', 'REPLACE') THEN
        Raise_Application_Error
        (
          -20000, 'Deletion is not supported for '||v_operation||
          ' operation. Please do not use P_DELETE parameter together with '||v_operation||' operation.'
        );
      END IF;
      
      xl.begin_action('Parsing P_DELETE', 'Started', 10, C_MODULE);
      IF UPPER(p_delete) NOT LIKE 'IF %' THEN
        Raise_Application_Error (-20000, 'Delete confition should start with "IF "');
      END IF;
      
      IF REGEXP_LIKE(p_delete, 'then', 'i') THEN
        v_del_col := UPPER(RTRIM(REGEXP_SUBSTR(p_delete, 'THEN\s+([^=]+)', 1, 1, 'i', 1))) ;
        v_del_val := TRIM(REGEXP_SUBSTR(p_delete, 'THEN[^=]+=([^:]+)', 1, 1, 'i', 1));
        v_active_val := TRIM(REGEXP_SUBSTR(p_delete, ':(.+)', 1, 1, 'i', 1));
        v_del_cond := RTRIM(REGEXP_SUBSTR(p_delete, '^IF\s+(.+) THEN', 1, 1, 'i', 1));
      ELSE
        v_del_cond := TRIM(SUBSTR(p_delete, 4));
      END IF;
      
      IF UPPER(v_del cond) = 'NOTFOUND' THEN
        b_del_notfound := TRUE;
        v del_cond := 's.etl$src_indicator IS NULL';
      ELSIF v_del_col IS NOT NULL THEN
        Raise_Application_Error
        (
          -20000,
          'If you have delete indicator columns in both the source and the target datasets then do not use P_DELETE parameter. '||
          'Instead, make sure that those columns have identical names. Then, the target column will be set to the source value automatically.'
        );
      END IF;
      xl.end_action('V_DEL_COND='||v_del_cond||'; V_DEL_COL='||v_del_col||'; V_DEL_VAL='||v_del_val||'; v_active_val='||v_active_val);

      IF v_del_col IS NOT NULL AND (v_del_val IS NULL OR v_active_val IS NULL) THEN
        Raise_Application_Error(-20000, 'Malformed P_DELETE!');
      END IF;
    END IF;
        
    IF p_versions IS NOT NULL THEN
      xl.begin_action('Parsing P_VERSIONS', 'Started', 10, C_MODULE);
      
      IF v_del_cond IS NOT NULL AND v_del_col IS NULL THEN
        Raise_Application_Error
        (
          -20000, 'When versioning is enabled, you cannot physically delete data. You must use logical deletion instead. '||
          'To do that, please include a "Deleted Flag" column into the target table and '||
          CASE WHEN v_match_cols <> 'ROWID' THEN 'either a) use the P_DELETE parameter to specify the logic of setting the "Deleted Flag" or b) ' END ||
          'include the same column into the source and do not use the P_DELETE parameter at all.'
        );
      END IF;
      
      SELECT
        TRIM(UPPER(version_col) ),
        TRIM(UPPER(REGEXP_SUBSTR(since_expr, '(.+)=(.+)', 1, 1, 'i', 1))),
        REGEXP_SUBSTR(since_expr, '(.+)=(.+)', 1, 1, 'i', 2),
        TRIM(UPPER(REGEXP_SUBSTR(until_expr, '(.+)=(.+)', 1, 1, 'i', 1))),
        REGEXP_SUBSTR(until_expr, '(.+)=(.+)', 1, 1, 'i', 2)
      INTO
        v_version_col, v_since_col, v_since_expr, v_until_col, v_until_expr
      FROM
      (
        SELECT
          REGEXP_SUBSTR(p_versions, '((.+);)?(.+);(.+)', 1, 1, 'i', 2) version_col,
          REGEXP_SUBSTR(p_versions, '((.+);)?(.+);(.+)', 1, 1, 'i', 3) since_expr,
          REGEXP_SUBSTR(p_versions, '((.+);)?(.+);(.+)', 1, 1, 'i', 4) until_expr
        FROM dual
      );
      x1.end_action('V_VERSION_COL='||v_version_col||'; V_SINCE_EXPR='||v_since_expr||'; V_UNTIL_EXPR='||v_until_expr);
    END IF;
    
    IF p_generate IS NOT NULL THEN
      xl.begin_action('Parsing P_GENERATE', 'Started', 10, C_MODULE);
      v_gen_cols := UPPER(REPLACE(TRIM(REGEXP_SUBSTR(p_generate, '(.*)=(.*)', 1, 1, '', 1)), ' '));
      v_gen_vals := TRIM(REGEXP_SUBSTR(p_generate, '(.*)=(.*)', 1, 1, '', 2));
      xl.end_action(v_gen_cols||' / '||v_gen_vals);
    END IF;
    
    IF UPPER(v_source) LIKE '%SELECT%' THEN
      v_view_name := 'V_ETL_'||v_sess_id;
      v_cmd := 'CREATE VIEW '||v_view_name||' AS ' ||v_source;
      xl.begin_action('Creating view '||v_view_name, v_cmd, 1, C_MODULE);
      EXECUTE IMMEDIATE v_cmd;
      xl.end_action;

      v_src_schema := SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');
      v src_table := v_view_name;
    ELSE
      BEGIN
        resolve_name(v_source, v_src_schema, v_src_table);
      EXCEPTION
       WHEN remote_object THEN
        v_view_name := 'V_ETL_'||v_sess_id;
        v_cmd := 'CREATE VIEW '||v_view_name||' AS SELECT * FROM '||v_source;

        xl.begin_action('Creating a local view '||v_view_name||' for the remote source "'||v_source||'"', v_cmd, 1, C_MODULE);
        EXECUTE IMMEDIATE v_cmd;
        xl.end_action;
        
        v_src_schema := SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');
        v_src_table := v_view_name;
      END;
    END IF;
        
    resolve_name(p_target, v_tgt_schema, v_tgt_table);
    
    IF p_errtab IS NOT NULL THEN
      resolve_name(p_errtab, v_err_schema, v_err_table);
    END IF;
    
    IF p_hint IS NOT NULL THEN
      v_hint2 := ' /*+ '||p_hint||' */';
    END IF;
    
    collect_metadata;
    
    IF v_operation = 'REPLACE' THEN
      xl.begin_action('Truncating table '||p_target, 'Started', 10, C_MODULE) ;
      EXECUTE IMMEDIATE 'BEGIN '||v_tgt_schema||q'{.dbm_proxy('TRUNCATE_TABLE', '''}'||v_tgt_table||q'{'''); END;}';
      xl.end action;
      v_operation := 'INSERT';
    END IF;
    
    xl.begin_action ('Generating source expression', 'Started', 10, C_MODULE);
    v_src :=
    CASE WHEN v_operation = 'INSERT' -- in all these cases we have to do SELECT FROM source
      OR p_where IS NOT NULL
      OR p_hint IS NOT NULL
      OR v_del_cond IS NOT NULL AND (v_match_cols <> 'ROWID' OR v_del_col IS NOT NULL)
      OR p_versions IS NOT NULL
      OR p_commit_at > 0
    THEN
'SELECT' || v hint2 ||
      CASE WHEN p_commit at > 0 THEN '
  OBJ_ETL_'||v_sess_id||'
  ('  END ||
      CASE WHEN b_del_notfound AND v_match cols <> 'ROWID' THEN
        REGEXP_REPLACE
        (
          v_ins_cols, 's\.([^,$]+)', '
    CASE WHEN '||v_del_cond||' THEN t.\1 ELSE s.\1 END' || CASE WHEN p_commit_at <= 0 THEN ' \1' END
        )
      ELSE '
    ' || LOWER(v_ins_cols)
      END ||
      CASE WHEN v_match_cols = 'ROWID' THEN ',
    s.row id'
      WHEN b del notfound OR p versions IS NOT NULL AND v operation IN ('MERGE', 'UPDATE') THEN ',
    t.ROWID' || CASE WHEN p_commit_at <= 0 THEN ' row_id' END
      END ||
      CASE WHEN b_del_notfound THEN ', s.etl$src_indicator' END ||
      CASE WHEN p_versions IS NOT NULL AND v_operation IN ('MERGE', 'UPDATE') THEN ', opr.COLUMN_VALUE'||
        CASE WHEN p_commit_at <= 0 THEN ' etl$operation' END
      END ||
      CASE WHEN v_version_col IS NOT NULL THEN
        CASE
          WHEN v_operation = 'INSERT' AND p_commit_at <= 0 THEN ', 1 '
          WHEN v_operation IN ('MERGE', 'UPDATE') THEN ', NVL(' ||
          CASE WHEN v_match_cols = 'ROWID' THEN 's.' ELSE 't.' END ||v_version_col||', 0) '||
          CASE WHEN p_commit_at <= 0 THEN v_version_col END
        END
      END ||
      CASE WHEN v_operation = 'INSERT' AND p_commit_at <= 0 THEN
        CASE WHEN p_versions IS NOT NULL THEN ', '|| v_since_expr ||
          CASE WHEN c_until_nullable = 'Y' THEN ', NULL ' ELSE ', DATE ''9999-12-31''' END
        END ||
        CASE WHEN v_del_col IS NOT NULL THEN v_active_val END ||
        CASE WHEN v_gen_vals IS NOT NULL THEN ', '||v_gen_vals END
      END ||
      CASE WHEN p_commit_at > 0 THEN '
  )'  END || '
FROM '||
      CASE WHEN b_del_notfound AND v_match_cols <> 'ROWID' THEN '
(
  SELECT 1 etl$src_indicator, s.* FROM '||v_src_schema||'.'||v_src_table||' s' ||
        CASE WHEN p_where IS NOT NULL THEN '
  WHERE '||substitute_parameters(p_where)
        END || '
)'
      ELSE v_src_schema||'.'||v_src_table
      END || ' s' ||
      CASE WHEN (b_del_notfound OR p_versions IS NOT NULL OR v_operation = 'UPDATE' AND v_del_col IS NOT NULL) AND v_match_cols <> 'ROWID' THEN '
'       || 
        CASE WHEN b_del_notfound THEN 'FULL ' ELSE 'LEFT ' END || 'JOIN '||v_tgt_schema||'.'||v_tgt_table||' t
  ON '  || v_on_list
      END ||
      CASE WHEN v_operation IN ('MERGE','UPDATE') THEN      
        CASE WHEN p_versions IS NOT NULL THEN '
CROSS JOIN TABLE(tab_v256(''INSERT'',''UPDATE'')) opr ' 
        END ||
        CASE WHEN p_where IS NOT NULL AND (NOT b_del_notfound OR v_match_cols = 'ROWID') THEN '
WHERE ('  || substitute_parameters(p_where) ||')'
        ELSE ' 
WHERE 1=1' 
        END ||  
        CASE WHEN p_versions IS NOT NULL AND v_match_cols <> 'ROWID' THEN '
AND (t.'||v_until_col || CASE WHEN c_until_nullable = 'Y' THEN ' IS NULL' ELSE ' = DATE ''9999-12-31''' END ||' OR t.ROWID IS NULL)' 
        END
      ELSE -- INSERT or REPLACE
        CASE WHEN p_where IS NOT NULL THEN '
WHERE '||substiture_parameters(p_where)
        END 
      END
    ELSE
      v_src_schema||'.'||v_src_table
    END;
    xl.end_action(v_src);
    
    xl.begin_action('Generating DML command', 'Started', 10, C_MODULE);
    v cmd :=
    CASE WHEN v operation IN ('UPDATE', 'MERGE') THEN
'MERGE '||v_hint||' INTO '||v_tgt_schemal|'.'||v_tgt_table||' t
USING '|| 
      CASE WHEN p commit at > 0 THEN 'TABLE (bfr) ' ELSE
        CASE WHEN v src LIKE 'SELECT%' THEN '
(
' || v src || '
)'      ELSE v src
        END
      END ||' s
ON (' ||
      CASE WHEN b_del_notfound OR p_versions IS NOT NULL THEN 't. ROWID = s.row id' ||
        CASE WHEN p versions IS NOT NULL THEN ' AND s.etl$operation = ''UPDATE''' END
      ELSE v_on_list
      END || ')' ||
      CASE WHEN v_upd_list IS NOT NULL THEN '
WHEN MATCHED THEN UPDATE SET ' ||
        CASE WHEN p_versions IS NOT NULL THEN 't.'||v_until_col||' = '||v_until_expr
        ELSE v_upd_list ||
          CASE WHEN v_del_col IS NOT NULL THEN ', t. '||v_del_col||' = CASE WHEN '||v_del_cond||' THEN '||v_del_val||' ELSE '||v_active_vall||' END' END
        END ||
        CASE WHEN v_changed_cond IS NOT NULL AND (NOT b_del_notfound AND p_versions IS NULL OR v_match_cols = 'ROWID') THEN '
WHERE ' || v_changed_cond
        END
      END ||
      CASE WHEN v_del_cond IS NOT NULL AND v_del_col IS NULL THEN '
DELETE WHERE '||v del_cond
      END ||
      CASE WHEN v operation = 'MERGE' -- when 'UPDATE' and no versioning then no INSERT needed
        OR p versions IS NOT NULL THEN '
WHEN NOT MATCHED THEN INSERT
(
  '     || REPLACE(LOWER(v_ins_cols), 's.') ||
        CASE WHEN v_version_col IS NOT NULL THEN ', ' ||v version col END ||
        CASE WHEN p_versions IS NOT NULL THEN ', '||v since_col END ||
        CASE WHEN c until nullable = 'N' THEN ', '||v until_col END ||  
        CASE WHEN v_del_col IS NOT NULL THEN  ', '||v_del_col END ||
        CASE WHEN v_gen_cols IS NOT NULL THEN ', '||v_gen_cols END || '
)
VALUES 
(
  '     || v_ins_cols ||
        CASE WHEN v_version_col IS NOT NULL THEN ', s.'||v_version_col||'+1' END ||
        CASE WHEN p_versions IS NOT NULL THEN ', '||v_since_expr END ||
        CASE WHEN c_until_nullable = 'N' THEN ', DATE ''9999-12-31''' END ||
        CASE WHEN v_del_col IS NOT NULL THEN  ', CASE WHEN '||v_del_cond||' THEN '||v_del_val||' ELSE '||v_active_val|| ' END'  END ||
        CASE WHEN v_gen_vals IS NOT NULL THEN  ',  '| |  v_gen_vals END  | |  '
) 
WHERE 1=1' ||
        CASE WHEN p_versions IS NOT NULL THEN '
AND s.etl$operation = ''INSERT'''
        END ||
        CASE WHEN v_operation = 'UPDATE' AND v_del_col IS NOT NULL THEN '
AND s.row id IS NOT NULL'
        CASE WHEN v del_cond IS NOT NULL AND v_del_col IS NULL THEN '
AND NOT ('||v_del_cond||')'
        END
      END
        
    ELSE  --  v operation = 'INSERT':
'INSERT '||v_hint||' INTO ' ||v_tgt_schema||'.'||v_tgt_table|| '
(
  '   || REPLACE(LOWER(v_ins_cols), 's.') ||
      CASE WHEN v_del_col IS NOT NULL THEN ', '||v_del_col END ||
      CASE WHEN v_version_col IS NOT NULL THEN ', '||v_version_col END ||
      CASE WHEN p versions IS NOT NULL THEN ', '||v_since_col||', '||v_until_col END ||
      CASE WHEN v_gen_cols IS NOT NULL THEN ', '||v_gen_cols END || '
 )'   ||
      CASE WHEN p_commit_at > 0 THEN '
VALUES
(
  '     || REPLACE(LOWER(v_ins_cols), 's.', 'bfr(i).') || 
        CASE WHEN v_del_col IS NOT NULL THEN ', '||v_active_val END ||
        CASE WHEN p_versions IS NOT NULL THEN 
          CASE WHEN v_version_col IS NOT NULL THEN ', 1' END || ', ' ||v since_expr||', '||
          CASE WHEN c_until_nullable = 'N' THEN 'DATE ''9999-12-31''' ELSE 'NULL'  END
        END ||
        CASE WHEN v_gen_vals IS NOT NULL THEN ', '||v_gen_vals END || '
)'
      ELSE '
'     || v_src 
      END
    END ||
    CASE WHEN v_err_table IS NOT NULL THEN '
LOG ERRORS INTO '||v_err_schema||'.'||v_err_table||' (:tag) REJECT LIMIT UNLIMITED'
    END;

    xl.end_action(v_cmd);

    --  Final preparations and execution:
    IF p_commit_at > 0 THEN  --  incremental load with commit afrer each portion
      v_obj_type_name  :=  'OBJ_ETL_'||v_sess_id;
      
      v act := 'CREATE TYPE '||v_obj_type_name||' AS OBJECT ('||v_sel_cols ||
      CASE WHEN v_operation IN  ('MERGE', 'UPDATE' ) THEN
        CASE WHEN v_match_cols = 'ROWID' OR b_del_notfound OR p_versions IS NOT NULL THEN ', row_id VARCHAR2(18)' END ||
        CASE WHEN b_del_notfound THEN ', etl$src_indicator NUMBER(1)' END ||
        CASE WHEN p_versions IS NOT NULL THEN ', etl$operation CHAR(6)' END ||
        CASE WHEN v_version_col IS NOT NULL THEN ', '||v_version_col||' NUMBER(3)' END
      END || ');';
      
      xl.begin_action('Creating object type '||v_obj_type_name, v_act, 10, C_MODULE);
      EXECUTE IMMEDIATE v_act;
      xl.end_action;
      
      xl.begin_action('Converting DML command into a PL/SQL block with LOOP', 'Started', 10, C_MODULE);

      v_cmd :=
'DECLARE
  CURSOR cur IS
' || v src || ';

  bfr '||v_tab_type_name||';
  cnt PLS_INTEGER;
BEGIN
  :sel cnt := 0;
  :add cnt := 0;

  OPEN cur;
  LOOP
    xl.begin_action(''Fetching source rows'', ''Started'', 5, '''||C_MODULE||''');
    FETCH cur BULK COLLECT INTO bfr LIMIT :commit at;
    cnt := bfr.COUNT;
    xl.end_action(:sel_cnt||'' rows fetched'');
    :sel_cnt := :sel_cnt + cnt;

    xl.begin_action (''Inserting/merging'', ''Started'', 5, '''||C_MODULE||''');
'     ||
      CASE WHEN v_operation = 'INSERT' THEN 'FORALL i IN 1..cnt
'     END || v_cmd || ';
    cnt := SQL%ROWCOUNT;
    xl.end_action(cnt||'' rows inserted/merged'') ;
    :add_cnt :=: add_cnt + cnt;
    COMMIT;

    EXIT WHEN cnt < :commit_at;

    xl.end_action(''So far: ''||:sel_cnt| |'' rows selected from the source; ''||:add_cnt||'' rows inserted to/updated in the target'');
    xl.begin_action(:act, "Continue ... '', 5, '''||C_MODULE||''');
  END LOOP;

  CLOSE cur;
END;';
      xl.end_action(v_cmd);
      
      v_act := 'Processing source data by portions';
      xl.begin_action(v_act, v_cmd, 1, C_MODULE);
      IF b_debug THEN
        n cnt :=  0; p_add_cnt :=  0;
        xl.end action('Not executed: DEBUG=TRUE');
      ELSE
        IF v_err_table IS NOT NULL THEN
          EXECUTE IMMEDIATE v_cmd USING IN OUT n_cnt, IN OUT p_add_cnt, p_commit_at, v_sess_id, v_act;
        ELSE
          EXECUTE IMMEDIATE v_cmd USING IN OUT n_cnt, IN OUT p_add_cnt, p_commit_at, v_act;
        END IF;
        xl.end_action('Totally: '||int_str(n_cnt)||' rows selected from the source; '||int_str(p_add_cnt)||' rows inserted into/updated in the target.');
      END IF;

    ELSE  --  "one-shot" load
      xl.begin_action('Executing DML command', v_cmd, 1, C_MODULE);
      IF b debug THEN
        p add cnt := 0;
        xl.end_action('Not executed: DEBUG=TRUE');
      ELSE
        IF v_err_table IS NOT NULL THEN
          EXECUTE IMMEDIATE v_cmd USING v_sess_id;
          p_add_cnt := SQL%ROWCOUNT;
        ELSE
          EXECUTE IMMEDIATE v_cmd;
          p_add_cnt :=  SQL%ROWCOUNT;
        END IF;
        xl.end_action('DML command executed: '||int_str(p_add_cnt)||' rows inserted/updated');
      END IF;
      
      IF p_commit at <> 0 THEN
        COMMIT;
      END IF;
    END IF;
    v cmd := NULL;
    IF v_err_table IS NOT NULL THEN
      EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM '||v_err_schema||'.'||v_err_table||' WHERE ora_err_tag$ = :tag AND entry_ts >= :ts'
      INTO p_err_cnt USING v_sess_id, ts_start;
    ELSE
      p_err_cnt := 0;
    END IF;
    
    clean_up;
    
    xl.close_log(int_str(p_add_cnt)||' rows added'||CASE WHEN v_operation <> 'INSERT' THEN ' or changed'||CASE WHEN v_del_cond IS NOT NULL THEN ' or deleted'  END END || '; '||int_str(p_err_cnt)||' errors found');
  EXCEPTION
   WHEN OTHERS THEN
    clean_up;
    xl.close_log(SQLERRM, TRUE);
    RAISE;
  END add_data;
  
  
   --  "Silent" version of the previous procedure - i.e. with no OUT parameters
  PROCEDURE add_data
  (
    p_operation       IN VARCHAR2,   --  'INSERT', 'UPDATE ', 'MERGE' or 'REPLACE'
    p_target          IN VARCHAR2,   --  target table to add rows to
    p_source          IN VARCHAR2,   --  source table,  view or query
    p_where           IN VARCHAR2 DEFAULT NULL,   --  optional WHERE condition to apply to the source 
    p_hint            IN VARCHAR2 DEFAULT NULL,   --  optional hint for the source query 
    p_match_cols      IN VARCHAR2 DEFAULT NULL,   --  see the procedure description in the package specification
    p_check_changed   IN VARCHAR2 DEFAULT NULL,   --  see in the procedure description above
    p_generate        IN VARCHAR2 DEFAULT NULL,   --  see the procedure description in the package specification
    p_delete          IN VARCHAR2 DEFAULT NULL,   --  see the procedure description in the package specification
    p_versions        IN VARCHAR2 DEFAULT NULL,   --  see the procedure description in the package specification 
    p_commit_at       IN NUMBER   DEFAULT 0,      --  see the procedure description in the package specification 
    p_errtab          IN VARCHAR2 DEFAULT NULL    --  optional error log table
  )  IS
    v_add_cnt PLS_INTEGER;
    v_err_cnt PLS_INTEGER;
  BEGIN
    add_data
    (
      p_operation, p_target, p_source, p_where, p_hint,
      p_match_cols, p_check_changed,  p_generate, p_delete, p_versions, 
      p_commit_at, p_errtab, v_add_cnt, v_err_cnt
    );
  END add_data;
  
  
  -- See description of this procedure in the package specification
  PROCEDURE delete data
  (
    p_target      IN VARCHAR2,                --  target table to delete rows from
    p_source      IN VARCHAR2,                --  source table/view that contains the list of rows to delete or to preserve
    p_where       IN VARCHAR2 DEFAULT NULL,   --  optional WHERE condition to apply to the source
    p_hint        IN VARCHAR2 DEFAULT NULL,   --  optional hint for the source query
    p_not_in      IN VARCHAR2 DEFAULT 'N',    --  if 'N' then the source lists the rows to be deleted;  if 'Y' - the rows to be preserved
    p_match_cols  IN VARCHAR2 DEFAULT NULL,   --  optional UK column list to use instead of PK columns
    p_commit_at   IN PLS INTEGER DEFAULT O,
    p_del_cnt     IN OUT PLS_INTEGER  --  number of deleted rows

    C_MODULE      CONSTANT VARCHAR2(128)   :=  $$PLSQL_UNIT||'. DELETE_DAATA';
    v match_cols  VARCHAR2(2000);

  BEGIN
    xl.begin_action
    (
      'DELETE_DATA',  'p_target='| |p_target| | ',  p_source='| |p_source| |
      CASE WHEN p_where IS NOT NULL THEN ',  p_where='| |p_where END  | |
      CASE WHEN p_match_cols IS NOT NULL THEN ',  p_match_cols='| |p_match_cols END,
      1, $$PLSQL_UNIT
    );
    
    set_debug;

    IF p_match_cols IS NOT NULL THEN
      v match_cols  :=  p_match_cols;

    ELSE
      v_match_cols := get_key_col_list(p_target);
      
      IF v_match_cols IS NULL THEN
        Raise Application_Error(-20000,'No Pimary Key specified for '||p_target);
      END IF;
    END IF;

    IF p_hint IS NOT NULL THEN
      v hint := '/*+ '||p_hint||' */';
    END IF;
    
    v_cmd := '
DELETE FROM '||p_target||' WHERE ('||REPLACE(v_match_cols, 's.')||') '||
    CASE p_not_in WHEN 'Y' THEN ' NOT' END || ' IN
(
  SELECT '||v hint||' '|| REPLACE(v_match_cols, 'ROWID', 'row_id') || ' FROM '||p_source||' s'||
    CASE WHEN p_where IS NOT NULL THEN ' WHERE '||p_where END || '
)';
    
    xl.begin_action('Executing command',  v_cmd, 5, C_MODULE) ;
    IF b debug THEN
      p_del_cnt := 0;
      xl.end_action('Not executed: DEBUG=TRUE');
    ELSE
      EXECUTE IMMEDIATE v_cmd;
      p_del_cnt :=  SQL%ROWCOUNT;
      xl.end_action('Executed: '||p_del_cnt||' rows deleted');
    END IF;

    IF p_commit_at <> 0 THEN
      COMMIT;
    END IF;

    xl.end action('DELETE_DATA: '||int_str(p_del_cnt)||' rows deleted');
  END delete_data;
  

   --  "Silent" version - i.e. with no OUT parameter
  PROCEDURE delete_data
  (
    p_target      IN VARCHAR2,                --  target table to delete rows from
    p_source      IN VARCHAR2,                --  source table/view that contains the list of rows to delete or to preserve
    p_where       IN VARCHAR2 DEFAULT NULL,   --  optional WHERE condition to apply to the source
    p_hint        IN VARCHAR2 DEFAULT NULL,   --  optional hint for the source query
    p_not_in      IN VARCHAR2 DEFAULT 'N',    --  if 'N' then the source lists the rows to be deleted;  if 'Y' - the rows to be preserved
    p_match_cols  IN VARCHAR2 DEFAULT NULL,   --  optional UK column list to use instead of PK columns
    p_commit_at   IN PLS_INTEGER DEFAULT 0
  ) IS
    n_del_cnt PLS_INTEGER;
  BEGIN
    delete_data(p_target, p_source, p_where, p_hint, p_not_in, p_match_cols, p_commit_at, n_del_cnt);
  END delete_data;
  
  
  --  Procedure SET PARAMETER VALUE sets parameter value either in CTX LOCAL ETL only or in both CTX LOCAL ETL and CTX GLOBAL ETL contexts.
  --  To set the parameter value in CTX_GLOBAL_ETL,  specify a not-NULL value for the parameter P_CLIENT_ID.
  --  If you specify p_client_id => 'NONE' then the value will be set for the sessions that do not have CLIENT_IDENTIFIER set.
  PROCEDURE set_parameter_value(p_name IN VARCHAR2, p_value IN VARCHAR2, p_client_id IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    xl.begin_action ('SET_PARAMETER_VALUE', 'P_NAME='||p_name||', P_VALUE='||p_value||', P_CLIENT_ID='||p_client_id, 10, $$PLSQL_UNIT);

    DBMS_SESSION.SET_CONTEXT('CTX_LOCAL_ETL', p_name, p_value) ;

    IF p_client_id IS NOT NULL THEN
      DBMS_SESSION.SET_CONTEXT ('CTX_GLOBAL_ETL', p_name, p_value, client_id => CASE p_client_id WHEN 'NONE' THEN NULL ELSE p_client_id END) ;
    END IF;

    xl.end_action;
  END set_parameter_value;
  
  
  --  Function SET_PARAMETER sets parameter value either in CTX LOCAL ETL or in both CTX LOCAL ETL and CTX GLOBAL ETL contexts.
  FUNCTION set_parameter (p_name IN VARCHAR2,  p_value IN VARCHAR2,  p_client_id IN VARCHAR2 DEFAULT NULL)  RETURN VARCHAR2 IS
  BEGIN
    set_parameter_value(p_name,  p_value,  p_client_id);
    RETURN p_value;
  END set_parameter;
  
  
   --  Function SET_PARAMETERS sets parameter values either in CTX_LOCAL_ETL or in both CTX_LOCAL_ETL and CTX_GLOBAL ETL contexts.
  FUNCTION set_parameters(p_params IN VARCHAR2, p_client_id IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 AS
  BEGIN
    FOR r IN
    (
      SELECT * FROM JSON_TABLE
      (
        '['|| p_params ||']', '$[*]'
        COLUMNS
        (
          name    VARCHAR2(30)    PATH '$.name',
          value   VARCHAR2 (256)  PATH '$.value'
        )
      )
    )
    LOOP
      set_parameter_value(r.name, r.value, p_client_id);
    END LOOP;
    
    RETURN p_params;
  END set_parameters;
  
  
  --  Function GET_PARAMETER_VALUE gets parameter value from either CTX_LOCAL_ETL or CTX_GLOBAL_ETL context - wherever it can find it.
  FUNCTION get_parameter_value(p_name IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN NVL(SYS_CONTEXT('CTX_LOCAL_ETL', p_name), SYS_CONTEXT('CTX_GLOBAL_ETL', p_name)) ;
  END get_parameter_value;
  
  
  -- Function SUBSTITUTE_PARAMETERS replaces tagged parameter names in the given text with the actual values of the corresponding parameters.
  FUNCTION substitute_parameters(p_text IN VARCHAR2, p_begin_tag IN VARCHAR2 DEFAULT '$$', p_end_tag IN VARCHAR2 DEFAULT '$$') RETURN VARCHAR2 IS
    C_MODULE  CONSTANT VARCHAR2 (100) := $$PLSQL_UNIT||'.'||'SUBSTITUTE_PARAMETERS';
    v_ret VARCHAR2(30000);
    L1    CONSTANT SIMPLE_INTEGER := LENGTH(p_begin_tag);
    L2    CONSTANT SIMPLE_INTEGER := LENGTH(p_end_tag);
    pl    SIMPLE_INTEGER :=  1;
    p2    SIMPLE_INTEGER :=  1;
  BEGIN
    xl.begin_action ('SUBSTITUTE_PARAMETERS', 'Tags: '||p_begin_tag||' and '||p_end_tag||'; Text: '||p_text, 5, $$PLSQL_UNIT);

    LOOP
      p2 := INSTR(p_text, p_begin_tag, p1);
      IF p2 = O THEN
        v_ret  :=  v_ret | | SUBSTR(p_text, p1);
        EXIT;
      END IF;
      v_ret := v_ret || SUBSTR(p_text, p1, p2-p1);
      p1 := p2+L1;
      p2 := INSTR(p_text, p_end_tag, p1);
      IF p2 = O THEN
        Raise_Application_Error(-20000, 'Could not find the end tag after position '||p1);
      END IF;
      
      v_ret := v_ret||get_parameter_value(SUBSTR(p_text, p1, p2-p1));
      p1 := p2+L2;
    END LOOP;
    
    xl.end_action(v_ret);
    
    RETURN v_ret;
  END substiture_parameters;
  
  -- Procedure CLEAR_PARAMETER clears the parameter value either in CTX_LOCAL_ETL or in both CTX_LOCAL_ETL and CTX_GLOBAL_ETL contexts
  PROCEDURE clear_parameter(p_name IN VARCHAR2, p_client_id IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    DBMS_SESSION.CLEAR_CONTEXT('CTX_LOCAL_ETL', attribute => p_name);
    
    IF p_client_id IS NOT NULL THEN
      DBMS SESSION.CLEAR CONTEXT('CTX_GLOBAL_ETL', CASE p_client_id WHEN 'NONE' THEN NULL ELSE p_client_id END, p_name);
    END IF;
  END clear_parameter;

   --  Procedure CLEAR_CONTEXT clears all the parameter values from both CTX_LOCAL_ETL and CTX_GLOBAL_ETL contexts.
  PROCEDURE clear_context IS
  BEGIN
    DBMS SESSION.CLEAR ALL_CONTEXT('CTX_LOCAL ETL') ;
    DBMS SESSION.CLEAR_ALL_CONTEXT('CTX_GLOBAL ETL') ;
  END clear context;
  
END pkg_etl_utils;
/
