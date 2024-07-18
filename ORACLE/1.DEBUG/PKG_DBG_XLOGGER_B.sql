CREATE OR REPLACE PACKAGE BODY pkg_dbg_xlogger AS
/*
  This package is for debugging and performance tuning
 
  History of changes - newest to oldest:
  ------------------------------------------------------------------------------
  18-Jul-2024, Oleg Khaykin (OK): new version;
*/
  TYPE typ_stats_record IS RECORD
  (
    tstamp        TIMESTAMP WITH TIME ZONE,
    cnt           PLS_INTEGER,
    dur           INTERVAL DAY TO SECOND
  );
  TYPE typ_stats_array IS TABLE OF typ_stats_record INDEX BY VARCHAR2(255);
 
  TYPE typ_action_record IS RECORD
  (
    module        dbg_log_data.module%TYPE,
    action        dbg_log_data.action%TYPE,
    log_in_table  BOOLEAN
  );
  TYPE typ_action_array IS TABLE OF typ_action_record INDEX BY PLS_INTEGER;
  
  TYPE typ_call_record IS RECORD
  (
    module        VARCHAR2(100),
    log_depth     dbg_log_data.log_depth%TYPE
  );
  TYPE typ_call_array IS TABLE OF typ_call_record INDEX BY PLS_INTEGER;
 
  TYPE typ_dump_array IS TABLE OF dbg_log_data%ROWTYPE INDEX BY PLS_INTEGER;
 
  stats_array     typ_stats_array;
  action_stack    typ_action_array;
  call_stack      typ_call_array;
  dump_array      typ_dump_array;
  
  v_main_module   VARCHAR2(256);
  rlog            dbg_process_logs%ROWTYPE;
  n_log_level     PLS_INTEGER;
  n_log_depth     dbg_log_data.log_depth%TYPE;
  n_call_depth    PLS_INTEGER;
  n_dump_idx      PLS_INTEGER;
  
  PROCEDURE set_log_level(p_session_client_id IN VARCHAR2, p_log_level IN PLS_INTEGER) IS
  BEGIN
    DBMS_SESSION.SET_CONTEXT('CTX_GLOBAL_DEBUG', 'LOG_LEVEL', TO_CHAR(p_log_level), NULL, p_session_client_id);
  END;
  
  PROCEDURE reset_log_level(p_session_client_id IN VARCHAR2) IS
  BEGIN
    DBMS_SESSION.CLEAR_CONTEXT('CTX_GLOBAL_DEBUG', p_session_client_id, 'LOG_LEVEL');
  END;
  
      
  PROCEDURE open_log
  (
    p_name      IN VARCHAR2,
    p_comment   IN CLOB DEFAULT NULL,
    p_log_level IN PLS_INTEGER DEFAULT 0,
    p_module    IN VARCHAR2 DEFAULT NULL,
    p_client_id IN VARCHAR2 DEFAULT 'DEFAULT'
  ) IS
    v_this_module VARCHAR2(128);
    
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    IF rlog.proc_id IS NULL THEN
      rlog := NULL;
      rlog.proc_id := seq_dbg_xlogger.NEXTVAL;
      rlog.name := CASE WHEN p_module IS NOT NULL THEN p_module||'.' END || p_name;
      rlog.comment_txt := p_comment;
      rlog.start_time := SYSTIMESTAMP;

      call_stack.DELETE;
      action_stack.DELETE;
      dump_array.DELETE;
      stats_array. DELETE;
      
      n_call_depth := 0;
      n_log_depth := 0;
      n_dump_idx := 1;
      
      SELECT NVL(MAX(log_level), NVL(p_log_level, 0)) INTO n_log_level
      FROM dbg_settings WHERE proc_name = rlog.name;

      IF n_log_level >= 0 THEN
        INSERT INTO dbg_process_logs VALUES rlog;
        COMMIT;
      END IF;

      v_main_module := SYS_CONTEXT('USERENV','MODULE');
      DBMS_SESSION.SET_IDENTIFIER(CASE p_client_id WHEN 'DEFAULT' THEN rlog.proc_id ELSE p_client_id END) ;
    END IF;

    v_this_module := NVL(p_module, p_name);
    DBMS_APPLICATION_INFO.SET_MODULE(v_this_module, NULL);
    n_call_depth := n_call_depth+1;
    call_stack(n_call_depth).module := v_this_module;
    call_stack(n_call_depth).log_depth := n_log_depth;

    begin_action(p_name, p_comment, CASE WHEN n_call_depth = 1 THEN n_log_level ELSE p_log_level END, NVL(p_module, 'NA'));
  END open_log;
  
  
  FUNCTION get_current_proc_id RETURN PLS_INTEGER IS
  BEGIN
    RETURN rlog.proc_id;
  END;
  

  PROCEDURE write_log
  (
    p_module  IN VARCHAR2,
    p_action    IN VARCHAR2, 
    p_comment   IN CLOB DEFAULT NULL, 
    p_persist   IN BOOLEAN
  ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
    dmp   dbg_log_data%ROWTYPE;
  BEGIN
    IF p_persist THEN
      INSERT INTO dbg_log_data(proc_id, tstamp, log_depth, module, action, comment_txt)
      VALUES(rlog.proc_id, SYSTIMESTAMP, n_log_depth, p_module, p_action, p_comment);
      
      COMMIT;
    ELSE
      dmp.proc_id := rlog.proc_id;
      dmp.tstamp := SYSTIMESTAMP;
      dmp.log_depth := n_log_depth;
      dmp.module := p_module;
      dmp.action := p_action;
      dmp.comment_txt := p_comment;
    
      dump_array(n_dump_idx) := dmp;
      n_dump_idx := MOD(n_dump_idx,1000)+1;
    END IF;
  END;
 
  
  PROCEDURE begin_action
  (
    p_action      IN VARCHAR2, 
    p_comment     IN CLOB DEFAULT 'Started', 
    p_log_level   IN PLS_INTEGER DEFAULT 1,
    p_module      IN VARCHAR2 DEFAULT NULL
  ) IS
    stk           typ_action_record;
    v_stats_idx   VARCHAR2(255);
  BEGIN
    DBMS_APPLICATION_INFO.SET_ACTION(p_action);
    
    IF rlog.proc_id IS NOT NULL THEN
      stk.module := NVL(p_module, 'NA');
      stk.action := p_action;
      
      IF p_log_level BETWEEN 0 AND NVL(TO_NUMBER(SYS_CONTEXT('CTX_GLOBAL_DEBUG', 'LOG_LEVEL')), n_log_level) THEN
        stk.log_in_table := TRUE;
      ELSE
        stk.log_in_table := FALSE;
      END IF;

      v_stats_idx := stk.module||'.'||stk.action;
      IF stats_array.EXISTS(v_stats_idx) AND stats_array(v_stats_idx).tstamp IS NOT NULL THEN
        -- This can happen due to a bug in the caller program:
        -- it is not allowed to begin the same action again without ending it first
        Raise_Application_Error(-20000, 'Action "'||v_stats_idx||'" has been already started! Correct mismatch between XL.BEGIN_ACTION and XL.END_ACTION calls.');
      ELSE
        -- Mark start of the action and put it into the action stack
        stats_array(v_stats_idx).tstamp := SYSTIMESTAMP;
        n_log_depth := n_log_depth+1;
        action_stack(n_log_depth) := stk;
      END IF;
      
      write_log(stk.module, p_action, p_comment, stk.log_in_table);
    END IF;
  END;
 
  
  PROCEDURE end_action(p_comment IN CLOB DEFAULT 'Completed') IS
    stk           typ_action_record;
    v_stats_idx   VARCHAR2(255);
  BEGIN
    IF rlog.proc_id IS NOT NULL THEN
      stk := action_stack(n_log_depth); -- get current action from the stack
      v_stats_idx := stk.module||'.'||stk.action;
    
      IF NOT stats_array.EXISTS(v_stats_idx) OR stats_array(v_stats_idx).tstamp IS NULL THEN
        -- This can happen only due to a bug in this program
        Raise_Application_Error(-20000, 'XL.END_ACTION: action "'||v_stats_idx||'" has not been started! This is a bug in PKG_DBG_XLOGGER!');
      END IF;
      
      stats_array(v_stats_idx).cnt := NVL(stats_array(v_stats_idx).cnt, 0) + 1; -- count occurances of this action
      stats_array(v_stats_idx).dur := NVL(stats_array(v_stats_idx).dur, INTERVAL '0' SECOND) + (SYSTIMESTAMP - stats_array(v_stats_idx).tstamp); -- add to total time spent on this action
      stats_array(v_stats_idx).tstamp := NULL; -- mark the end of the action
      
      write_log(stk.module, stk.action, p_comment, stk.log_in_table);
      
      n_log_depth := n_log_depth-1; -- go up by the action stack
      IF n_log_depth > 0 THEN
        DBMS_APPLICATION_INFO.SET_ACTION(action_stack(n_log_depth).action);
      ELSE
        DBMS_APPLICATION_INFO.SET_ACTION(NULL);
      END IF;
    END IF;
  END;
  
  
  PROCEDURE close_log(p_result IN VARCHAR2 DEFAULT NULL, p_dump IN BOOLEAN DEFAULT FALSE) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  
    v_act     dbg_log_data.action%TYPE;
    n_seconds NUMBER;
    
    PROCEDURE set_seconds(p_interval INTERVAL DAY TO SECOND) IS
    BEGIN
      n_seconds := 
      EXTRACT(DAY FROM p_interval)*86400 +
      EXTRACT(HOUR FROM p_interval)*3600 +
      EXTRACT(MINUTE FROM p_interval)*60 +
      EXTRACT(SECOND FROM p_interval);
    END;
  BEGIN
    IF rlog.proc_id IS NOT NULL THEN -- if logging has been started in this session:
      WHILE n_log_depth > call_stack(n_call_depth).log_depth LOOP
        end_action(p_result);
      END LOOP;
      
      n_call_depth := n_call_depth-1; -- go up by the call stack:
      IF n_call_depth > 0 THEN
        DBMS_APPLICATION_INFO.SET_MODULE(call_stack(n_call_depth).module, NULL);
      ELSE
        DBMS_APPLICATION_INFO.SET_MODULE(v_main_module, NULL);
      END IF;
      
      IF n_call_depth = 0 THEN -- if this is the end of the main process
        rlog.result := p_result;
        rlog.end_time := SYSTIMESTAMP;
       
        IF n_log_level < 0 THEN
          set_seconds(rlog.end_time - rlog.start_time);
            
          IF p_dump OR n_seconds >= ABS(n_log_level) THEN
            INSERT INTO dbg_process_logs VALUES rlog;
          END IF;
        END IF;
        
        -- Save log data accumulated in memory:
        IF p_dump AND dump_array.COUNT > 0 THEN
          FORALL i IN 1..dump_array.COUNT INSERT INTO dbg_log_data VALUES dump_array(i);
          dump_array.DELETE;
          n_dump_idx := 1;
        END IF;
        
        -- Save performance statistics accumulated in memory:
        IF n_log_level >= 0 OR p_dump OR n_seconds >= ABS(n_log_level) THEN
          v_act := stats_array.FIRST;
          
          WHILE v_act IS NOT NULL LOOP
            set_seconds(stats_array(v_act).dur);
            
            INSERT INTO dbg_performance_data(proc_id, action, cnt, seconds)
            VALUES(rlog.proc_id, v_act, stats_array(v_act).cnt, n_seconds);
                
            v_act := stats_array.NEXT(v_act);
          END LOOP;
        
          UPDATE dbg_process_logs SET end_time = SYSTIMESTAMP, result = p_result
          WHERE proc_id = rlog.proc_id;
        END IF;
        
        rlog.proc_id := NULL;
      END IF; -- n_call_depth = 0
      
      COMMIT;
    END IF;
  END;
  
  
  PROCEDURE spool_log(p_where IN VARCHAR2 DEFAULT NULL, p_max_rows IN PLS_INTEGER DEFAULT 1000) IS
    cur     SYS_REFCURSOR;
    whr     VARCHAR2(128);
    line    VARCHAR2(255);
  BEGIN
    whr := NVL(p_where,'comment_txt NOT LIKE ''Started%''');
    
    OPEN cur FOR '
    SELECT * FROM
    (
      SELECT SUBSTR(action||'': ''||comment_txt, 1, 254)
      FROM dbg_log_data
      WHERE proc_id = xl.get_current_proc_id AND '||whr||'
      ORDER BY tstamp
    ) l
    WHERE ROWNUM < :max_rows' USING p_max_rows;
    
    LOOP
      FETCH cur INTO line;
      EXIT WHEN cur%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(line||CHR(10));
    END LOOP;
    
    CLOSE cur;
  END;
  
  
  PROCEDURE cancel_log IS
  BEGIN
   IF rlog.proc_id IS NOT NULL THEN
      n_call_depth := 1;
      close_log('Cancelled');
    END IF;
  END;
  
  
  PROCEDURE drop_old_partitions(p_preserve IN PLS_INTEGER DEFAULT 2) IS
    PROCEDURE alter_fks (p_enable_disable IN VARCHAR2) IS
    BEGIN
      FOR r IN
      (
        SELECT table_name, constraint_name
        FROM user_constraints
        WHERE table_name IN ('DBG_LOG_DATA', 'DBG_PERFORMANCE_DATA')
        AND constraint_type = 'R'
        AND status NOT LIKE p_enable_disable||'%'
      )
      LOOP
        EXECUTE IMMEDIATE 'ALTER TABLE '||r.table_name||' MODIFY CONSTRAINT '||r.constraint_name||' '||p_enable_disable;
      END LOOP;
    END;
  BEGIN
    xl.open_log('DROP_OLD_PARTITIONS', 'P_PRESERVE='||p_preserve, 1, $$PLSQL_UNIT) ;
    
    alter_fks('DISABLE');
    
    FOR r IN
    (
      SELECT table_name, partition_name, partition_position
      FROM
      (
        SELECT
          table_name, partition_name, partition_position,
          ROW_NUMBER () OVER(PARTITION BY table_name ORDER BY partition_position DESC) rnum
        FROM all_tab_partitions
        WHERE table_owner = SYS_CONTEXT ( 'USERENV', 'CURRENT_SCHEMA')
        AND table_name IN ('DBG_LOG_DATA', 'DBG_PERFORMANCE_DATA', 'DBG_PROCESS_LOGS')
      )
      WHERE rnum > GREATEST (2, p_preserve) -- never drop the last 2 partitions
      ORDER BY DECODE (table_name, 'DBG_PERFORMANCE_DATA', 1, 'DBG_LOG_DATA', 2, 3), partition_position
    )
    LOOP
      EXECUTE IMMEDIATE 'ALTER TABLE '||r. table_name||' DROP PARTITION '||r.partition_name;
    END LOOP;
    
    alter_fks('ENABLE') ;
    
    xl.close_log('Successfully completed');
  EXCEPTION
   WHEN OTHERS THEN
    xl.close_log(SQLERRM, TRUE) ;
    RAISE;
  END;
END;
/
