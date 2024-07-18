DECLARE
  C_SCHEMA    CONSTANT VARCHAR2(30) := SYS_CONTEXT ('USERENV', 'CURRENT_SCHEMA');

  PROCEDURE exec_sql (p_sql IN VARCHAR2) IS
  BEGIN
    dbms_output.put_line(SUBSTR(p_sql, 1, 255));
    EXECUTE IMMEDIATE p_sql;
    END;
BEGIN
  FOR r IN
  (
    SELECT d.object_name
    FROM
    (
      SELECT 1 rnum, 'SEQ_DBG_XLOGGER' object_name FROM dual UNION ALL
      SELECT 2, 'DBG_PROCESS_LOGS' object_name FROM dual UNION ALL
      SELECT 3, 'DBG_LOG_DATA' object_name FROM dual UNION ALL
      SELECT 4, 'DBG_PERFORMANCE_DATA' object_name FROM dual UNION ALL
      SELECT 5, 'DBG_SETTINGS' FROM dual
    ) d
    LEFT JOIN all_objects o
      ON o.owner = C_SCHEMA
    AND o.object_name = d.object_name
    WHERE o.object_name IS NULL
    ORDER BY d.rnum
  )
  LOOP
    CASE r.object_name
      WHEN 'SEQ_DBG_XLOGGER' THEN
        exec_sql('CREATE SEQUENCE seq_dbg_xlogger INCREMENT BY 1 NOCACHE') ;

      WHEN 'DBG_PROCESS_LOGS' THEN
        exec_sql('
CREATE TABLE dbg_process_logs
(
  proc_id       INTEGER NOT NULL,
  name          VARCHAR2(100) NOT NULL,
  comment_txt   VARCHAR2(2048),
  start_time    TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
  end_time      TIMESTAMP(6),
  result        VARCHAR2(2048),
  CONSTRAINT pk_dbg_process_logs PRIMARY KEY (proc_id) USING INDEX LOCAL
)
PARTITION BY RANGE (proc_id) INTERVAL(100000)
(
  PARTITION pl VALUES LESS THAN(100000)
)');

        exec_sql('CREATE INDEX ix_dbg_process_logs_name ON dbg_process_logs (name) LOCAL') ;

      WHEN 'DBG_LOG_DATA' THEN
        exec_sql('
CREATE TABLE dbg_log_data
(
  proc_id       INTEGER       NOT NULL,
  tstamp        TIMESTAMP(6)  NOT NULL,
  log_depth     NUMBER(2)     NOT NULL,
  module        VARCHAR2(128) DEFAULT ''NA'' NOT NULL,
  action        VARCHAR2(255) NOT NULL,
  comment_txt   CLOB,
  CONSTRAINT fk_logdata_proc FOREIGN KEY (proc_id) REFERENCES dbg_process_logs (proc_id) ON DELETE CASCADE
)
PARTITION BY RANGE(proc_id) INTERVAL(100000)
(
  PARTITION pl VALUES LESS THAN(100000)
)');
        exec_sql('CREATE INDEX x_dbg_log_data_procid ON dbg_log_data(proc_id) LOCAL');

      WHEN 'DBG_PERFORMANCE_DATA' THEN
        exec_sql('
CREATE TABLE dbg_performance_data
(
  proc_id       INTEGER       NOT NULL,
  action        VARCHAR2(255) NOT NULL,
  cnt           NUMBER(10)    NOT NULL,
  seconds       NUMBER        NOT NULL,
  CONSTRAINT pk_perfdata PRIMARY KEY(proc_id, action) USING INDEX LOCAL,
  CONSTRAINT fk_perfdata_proc FOREIGN KEY(proc_id) REFERENCES dbg_process_logs ON DELETE CASCADE
)
PARTITION BY RANGE(proc_id) INTERVAL(100000)
(
  PARTITION pl VALUES LESS THAN(100000)
)');

      WHEN 'DBG_SETTINGS' THEN
        exec_sql('
CREATE TABLE dbg_settings
(
  proc_name VARCHAR2 (100) CONSTRAINT pk_dbg_settings PRIMARY KEY,
  log_level NUMBER (4) DEFAULT 0 NOT NULL                         
)');

        exec_sql('COMMENT ON COLUMN dbg_settings. log_level IS ''Negative number taken by its absolute value designates the minimal number of seconds that the process should run from start to end to be logged in database tables''');
    END CASE;
  END LOOP;
END;
/