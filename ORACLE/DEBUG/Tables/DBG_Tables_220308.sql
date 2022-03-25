DECLARE
  C_SCHEMA    CONSTANT VARCHAR2(30) := SYS_CONTEXT('USERENV','CURRENT_SCHEMA');
  C_CUTOFF    CONSTANT CHAR(7) := '1800000';
  C_PART_SIZE CONSTANT CHAR(6) := '100000';
  
  PROCEDURE exec_sql(p_sql IN VARCHAR2) IS
  BEGIN
    dbms_output.put_line(SUBSTR(p_sql, 1, 255));
    EXECUTE IMMEDIATE p_sql;
  END;
  
BEGIN
  FOR r IN
  (
    SELECT table_name FROM dba_tables 
    WHERE owner = C_SCHEMA AND table_name = 'DBG_SUPPLEMENTAL_DATA'
  )
  LOOP
    exec_sql('DROP TABLE '||r.table_name||' PURGE');
  END LOOP;
  
  FOR r IN
  (
    SELECT table_name, REPLACE(table_name, 'DBG', 'BKP') bkp_name
    FROM dba_part_tables
    WHERE owner = C_SCHEMA AND table_name IN ('DBG_PROCESS_LOGS','DBG_LOG_DATA','DBG_PERFORMANCE_DATA')
    AND interval = '1000'
  )
  LOOP
    exec_sql('ALTER TABLE '||r.table_name||' RENAME TO '||r.bkp_name);
  END LOOP;
  
  FOR r IN
  (
    SELECT table_name, constraint_name
    FROM dba_constraints
    WHERE table_name IN ('BKP_LOG_DATA','BKP_PERFORMANCE_DATA')
    AND constraint_type = 'R'
  )
  LOOP
    exec_sql('ALTER TABLE '||r.table_name||' DROP CONSTRAINT '||r.constraint_name); 
  END LOOP;
  
  FOR r IN
  (
    SELECT lst.object_type, lst.object_name
    FROM
    (
      SELECT 'TABLE' object_type, 'DBG_PROCESS_LOGS' object_name FROM dual UNION ALL
      SELECT 'TABLE', 'DBG_LOG_DATA' FROM dual UNION ALL
      SELECT 'TABLE', 'DBG_PERFORMANCE_DATA' FROM dual UNION ALL
      SELECT 'INDEX', 'IX_DBG_PROCLOG_NAME' FROM dual UNION ALL
      SELECT 'INDEX', 'FKI_DBG_LOGDATA_PROC' FROM dual UNION ALL
      SELECT 'INDEX', 'FKI_DBG_PERFDATA_PROC' FROM dual
    ) lst
    LEFT JOIN dba_objects o
      ON o.owner = C_SCHEMA AND o.object_name = lst.object_name
    WHERE o.owner IS NULL
  )
  LOOP
    CASE r.object_name
      WHEN 'DBG_PROCESS_LOGS' THEN
        exec_sql
        (
'CREATE TABLE dbg_process_logs
(
  proc_id     INTEGER CONSTRAINT pk_dbg_proc_logs PRIMARY KEY USING INDEX LOCAL,
  name        VARCHAR2(100) NOT NULL,
  comment_txt varchar2(1000) NOT NULL,
  start_time  TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
  end_time    TIMESTAMP(6),
  result      VARCHAR2(2048)
)
PARTITION BY RANGE(proc_id) INTERVAL('||C_PART_SIZE||')
(
  PARTITION p0 VALUES LESS THAN ('||C_CUTOFF||')
)'      );
 
      WHEN 'DBG_LOG_DATA' THEN
        exec_sql
        (
'CREATE TABLE dbg_log_data
(
  proc_id      NUMBER(30) NOT NULL,
  tstamp       TIMESTAMP(6) NOT NULL,
  log_depth    NUMBER(2) NOT NULL,
  pls_unit     VARCHAR2(128) DEFAULT ''NA'' NOT NULL,
  action       VARCHAR2(255) NOT NULL,
  comment_txt  CLOB,
  CONSTRAINT fk_dbglogdata_proc FOREIGN KEY(proc_id) REFERENCES dbg_process_logs ON DELETE CASCADE
)
PARTITION BY RANGE(proc_id) INTERVAL('||C_PART_SIZE||')
(
  PARTITION p0 VALUES LESS THAN ('||C_CUTOFF||')
)'      );

      WHEN 'DBG_PERFORMANCE_DATA' THEN
        exec_sql
        (
'CREATE TABLE dbg_performance_data
(
  proc_id    NUMBER(30),
  action     VARCHAR2(255),
  cnt        NUMBER(10),
  seconds    NUMBER,
  CONSTRAINT pk_dbg_perf_data PRIMARY KEY(proc_id, action) USING INDEX LOCAL, 
  CONSTRAINT fk_dbg_perfdata_proc FOREIGN KEY(proc_id) REFERENCES dbg_process_logs ON DELETE CASCADE
)
PARTITION BY RANGE(proc_id) INTERVAL('||C_PART_SIZE||')
(
  PARTITION p0 VALUES LESS THAN ('||C_CUTOFF||')
)'      );
    
      WHEN 'IX_DBG_PROCLOG_NAME' THEN
        exec_sql('CREATE INDEX '||r.object_name||' ON dbg_process_logs(name) LOCAL');
        
      WHEN 'FKI_DBG_LOGDATA_PROC' THEN
        exec_sql('CREATE INDEX '||r.object_name||' ON dbg_log_data(proc_id) LOCAL');

      WHEN 'FKI_DBG_PERFDATA_PROC' THEN
        exec_sql('CREATE INDEX '||r.object_name||' ON dbg_performance_data(proc_id) LOCAL');
    END CASE;

    CASE r.object_type 
     WHEN 'TABLE' THEN
      exec_sql('GRANT SELECT ON '||r.object_name||' TO PUBLIC');
      exec_sql('ALTER TABLE '||r.object_name||' NOPARALLEL');
     ELSE
      exec_sql('ALTER INDEX '||r.object_name||' NOPARALLEL');
    END CASE;
  END LOOP;
  
  FOR r IN
  (
    SELECT REPLACE(table_name, 'BKP', 'DBG') tab_name, table_name AS bkp_name
    FROM dba_tables
    WHERE owner = C_SCHEMA AND table_name IN ('BKP_PROCESS_LOGS','BKP_LOG_DATA','BKP_PERFORMANCE_DATA')
    ORDER BY DECODE(table_name, 'BKP_PROCESS_LOGS', 1, 'BKP_LOG_DATA', 2, 3)
  )
  LOOP
    exec_sql('INSERT /*+ APPEND */ INTO '||r.tab_name||' SELECT * FROM '||r.bkp_name||' WHERE proc_id >= '||C_CUTOFF||' AND NOT EXISTS (SELECT 1 FROM '||r.tab_name||')');
    exec_sql('DROP TABLE '||r.bkp_name||' PURGE');
  END LOOP;
END;
/