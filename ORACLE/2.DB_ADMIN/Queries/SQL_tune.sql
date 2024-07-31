ALTER SESSION SET nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET "_pivot_implementation_method"='PIVOT2'; 

SELECT sys_context('USERENV','INSTANCE') FROM dual; 

-- Parameters for automatic SQL tuning: 
SELECT * FROM v$parameter
WHERE name IN 
(
  'cursor_sharing',                       -- EXACT | FORCE - this is what we want
  'optimizer_capture_sql_plan_baselines', -- if TRUE then every new plan will be automatically capured in a Baseline
  'optimizer_use_sql_plan_baselines',     -- if TRUE then the optimizer will use SQL Plan Baselines
  'control_management_pack_access',       -- NONE | DIAGNOSTIC | DIAGNOSTIC+TUNING - this is what we want 
  'statistics_level'                      -- ALL I TYPICAL I BASIC, ideally - ALL
)
ORDER BY name;

--================  Current SQLs and their execution plans: ====================
-- Execution statistics of a currently running SQL: 
SELECT * FROM gv$sqlarea WHERE sql_id = '5592db8p0fwx2'; 

-- Execution statistics of every child cursor of the SQLs that are stillin SGA: 
SELECT 
  --*
  sql_id, child_number, plan_hash_value, inst_id, sql_fulltext 
FROM gv$sql 
WHERE 1=1 AND sql_id = '54wtjbrvjb3q5' 
--AND inst_id = 0 
--AND UPPER(sql_text) like '%ODF%' 
;

-- Execution plans that are still in SGA:
SELECT
  *
  --address, hash value 
FROM gv$sql_plan WHERE sql_id = 'bvyj6nja7gqz6'; 

-- To purge a plan from SGA:
-- name: (address, hash value}, flag: C-cursor 
exec dbms_shared_pool.purge(name=>'000000085fd77cf0, 808321886', flag=>'C');

-- To see the plan in SGA: 
SELECT * FROM TABLE
(
  dbms_xplan.display_cursor 
  (
    sql_id          => '5592db8p0fwx2',
    cursor_child_no => 1,
    format => 'ALL'
  )
);

--------------------------------------------------------------------------------
-- SQLs captured in AWR:
SELECT
  *
  --sql_id, sql_text 
FROM dba hist_sqltext
WHERE 1=1
AND sql_id = '5592db8p0fwx2'
--AND sql_text LIKE 'INSERT INTO MRDM META. TMP$_BATCH_ID_TAB XREF%'
;

-- Execution plans captured in AWR:
SELECT DISTINCT sql_id, plan_hash_value
FROM dba_hist_sql_plan
WHERE sql_id = '5592db8p0fwx2'
--AND plan_hash value = 561842141
;

-- To see the plan captured in AWR: 
SELECT * FROM TABLE 
(
  dbms_xplan.display_awr 
  (
    sql_id => '5592db8p0fwx2',
    plan_hash_value => 561842141,
    format => 'ALL' -- TYPICAL, BASIC, SERIAL, ALL; default - TYPICAL 
  )
);

--================= -- Manual SQL plan analysis: ===============================
DELETE FROM plan_table WHERE statement_id = 'OK'; 
COMMIT; 

EXPLAIN PLAN SET statement_id = 'OK' FOR
INSERT --+ parallel(32) append 
INTO tmp_edp_risk measure 
WITH
  param AS
  (
    SELECT --+ materialize 
      set_parameter('COB_DATE', DATE '2022-12-30')
    FROM dual
  )
SELECT --+ px_join_filter(@sel$2 cv)
  v.* 
FROM param p CROSS JOIN v edp_risk_peasurecv;

-- To see the plan as a table output: 
SELECT * FROM TABLE(dbms_xplan.display(statement_id=>'0K', format=>'ALL')); 

-- To see the plan as CLOB: 
SELECT dbms_xplan.display_plan
(
  -- table_name => 'PLAN_TABLE',
  statement_id => 'OK',
  format => 'ALL', -- many options 
  --filter_preds => 'plan_id=705131426',
  type => 'TEXT'
)
FROM dual; 

--==================== Tuning SQL using DBMS_SQLTUNE: ==========================
-- 1. Grant proper privileges to the tuner: 
GRANT ADVISOR TO onerisk_dev; 
GRANT ADMINISTER SQL TUNING SET TO onerisk_dev; 
GRANT ADMINISTER ANY SQL TUNING SET TO onerisk_dev; 
GRANT SELECT ANY DICTIONARY TO onerisk_dev; 
GRANT CREATE ANY SQL PROFILE, DROP ANY SQL PROFILE, ALTER ANY SQL PROFILE TO one isk dev; 

SELECT privilege, grantee
FROM dba_sys_privs 
WHERE privilege IN ('ADVISOR','ADMINISTER SQL TUNING SEI','ADMINISTER ANY SQL TUNING SET', 'SELECT ANY DICTIONARY', 'CREATE ANY SQL PROFILE', 'DROP ANY SQL PROFILE', 'ALTER ANY SQL PROFILE')
AND (grantee = USER OR grantee IN (SELECT role FROM session_roles))
ORDER BY privilege, grantee; 

-- 2. Create/drop SQL tuning task: 
-- 2-a. Create tuning task for a known SQL: 
DECLARE
  my_task_name VARCHAR2(30);
  my_sqltext CLOB;
BEGIN
  my_sqltext := 'SELECT COUNT(1) cnt FROM mrdm calculated value WHERE cob date = :cob date';
  my_task_name := dbms_sqltune.create_tuning_task
  (
    sql_text => my_sqltext,
    bind_list => sql_binds(ANYDATA.ConvertDate('22-JUL-2022')),
    user_name => 'MRDM',
    scope => 'COMPREHENSIVE',
    time_limit => 600,
    task_name => 'OK TUNE',
    description => 'Task to tune the given SQL' 
  );
END; 
/

-- 2-b. Create a tuning task for a known SQL ID: 
DECLARE
  my_task_name VARCHAR2(30);
BEGIN
  my_task_name := dbms_sqltune.create_tuning_task
  (
    sql_id => '5592db8p0fwx2',
    plan_hash_value => NULL,
    scope => 'COMPREHENSIVE',
    task_name => 'OK TUNE_SQL',
    description => NULL,
    con name => NULL
  );
END; 
/

-- 2-d. See existing tasks: 
SELECT * FROM dba_advisor_tasks WHERE task_name like 'OK TUNE%' ORDER BY created DESC; 

-- 3. Execute the task: 
--exec dbms_sqltune.set_tuning_task_parameter('OK TUNE_SQL','TIME_LIMIT','300');
exec dbms_sqltune.execute_tuning_task(task_name => 'OK TUNE_SQL');

-- 4. Monitor the task execution and see the results:
SELECT advisor_name, sofar, totalwork, recommendations FROM v$advisor_progress WHERE task id = 299092; 

-- 5.See the recommendations:
SELECT dbms_sqltune.report_tuning_task('OK TUNE_SQL') FROM dual; 

-- 6. Accept the profile:
DECLARE
  profile_name VARCHAR2(30);
BEGIN
  profile_name := dbms_sqltune.accept_sql_profile 
  (
    task_name => 'OK_TUNE_SQL',
    name => 'OK PF_fgh9j58axzu7x',
    force match => TRUE
  );
END;
/

-- OR:
execute dbms_sqltune.accept_sql_profile(task_name => 'OK_TUNE_SQL', task_owner 'ONERISK_DEV', replace => TRUE);
-- OR:
execute dbms_sqltune.accept_sql_profile(task_name =>'0K TUNE bvyj6nja7gqz6', tas _owner => 'ONERISK DEV', replace => TRUE, force match => TRUE);

-- 7. See the generated SQL profiles and SQL outlines:
SELECT * FROM dba_sql_profiles ORDER BY created desc;
SELECT * FROM dba_outlines;
SELECT * FROM dba_outline hints; 

-- 8. Drop the tuning task: 
exec dbms_sqltune.drop_tuning_task('OK_TUNE_SQL'); 

-- 9. Drop SQL profile if it is no longer needed: 
exec dbms_sqltune.drop_sql_profile('PF_OK_bvyj6nja7gqz6'); 

--====================== SQL execution plan baselines: =========================
SELECT * FROM v$parameter WHERE name like '%baseline%'; 

-- 1. Create a baseline: 

-- 1a: Create a baseline recommended by a tuning task:
exec dbms_sqltune.create_sql_plan_baseline(task_name => 'OK_TUNE_SQL', owner_name => 'SYSTEM', plan_hash_value => 3693189077); 

-- 1b: Load a plan captured in AWR: 
DECLARE
  n_plans_loaded PLS_INTEGER;
BEGIN
  n_plans_loaded := dbms_spm.load_plans_from_awr 
  (
    begin_snap => 12982,
    end_snap => 12985,
    basic_filter => 'sgl_id = ''5592db8p0fwx2'''
    --basic_filter => 'and sgl_text like ''select 1 from ( select mrdminstru0_%'''
    --,fixed => 'NO',
    --,enabled => 'YES',
    --,commit_rows => 1000 
  );
END;
/

-- 2. See existing baslines: 
SELECT 
  --*
  sql_handle, sql_text, 
  plan_name, origin, created, 
  enabled, accepted, fixed, reproduced, autopurge, adaptive
FROM dba_sql_plan_baselines; 

-- 2a - see particular plans: 
SELECT * FROM TABLE
(
  dbms_xplan.display_sql_plan_baseline 
  (
    sql_handle => 'SQL_2eldcc667a5f6673',
    plan_name => 'SQL_PLAN_2w7fcctx5ytmm73d96bf5'
  )
);

-- 3. To fix (i.e. "pin") the plan in a baseline:
DECLARE
  n_altered PLS_INTEGER;
BEGIN
  n_altered := dbms_spm.alter_sql_plan_baseline
  (
    sql_handle => 'SQL_2eldcc667a5f6673',
    plan_name => 'SQL_PLAN_2w7fcctx5ytmm73d96bf5',
    attribute_name => 'FIXED',
    attribute_value => 'YES'
  );
END; 
/

-- 4.Drop plan(s) from a baseline:
DECLARE
  n_dropped PLS_INTEGER;
BEGIN
  n_dropped := dbms_spm.drop_sql_plan_baseline
  (
    --sql_handle => 'SQL_2eldcc667a5f6673',
    plan_name => 'SQL_PLAN_2w7fcctx5ytmm7e92de98'
  );
END;
/
