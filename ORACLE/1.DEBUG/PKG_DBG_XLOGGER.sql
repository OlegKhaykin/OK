CREATE OR REPLACE PACKAGE pkg_dbg_xlogger AS
/*
  This package is for debugging and performance tuning
 
  History of changes (newest to oldest):
  -------------------------------------------------------------------------------
  18-Jul-2024, Oleg Khaykin (OK): new version;
*/
  PROCEDURE set_log_level(p_session_client_id IN VARCHAR2, p_log_level IN PLS_INTEGER);
  
  PROCEDURE reset_log_level(p_session_client_id IN VARCHAR2);
  
  PROCEDURE open_log
  (
    p_name        IN VARCHAR2,
    p_comment     IN CLOB DEFAULT NULL, 
    p_log_level   IN PLS_INTEGER DEFAULT 0,
    p_module      IN VARCHAR2 DEFAULT NULL,
    p_client_id   IN VARCHAR2 DEFAULT 'DEFAULT'
  );
 
  FUNCTION get_current_proc_id RETURN PLS_INTEGER;
 
  PROCEDURE begin_action
  (
    p_action      IN VARCHAR2, 
    p_comment     IN CLOB DEFAULT 'Started',
    p_log_level   IN PLS_INTEGER DEFAULT 1,
    p_module      IN VARCHAR2 DEFAULT NULL
  );
 
  PROCEDURE end_action(p_comment IN CLOB DEFAULT 'Completed');
  
  PROCEDURE close_log(p_result IN VARCHAR2 DEFAULT NULL, p_dump IN BOOLEAN DEFAULT FALSE);
  
  PROCEDURE spool_log(p_where IN VARCHAR2 DEFAULT NULL, p_max_rows IN PLS_INTEGER DEFAULT 1000);
 
  PROCEDURE cancel_log;
 
  PROCEDURE drop_old_partitions(p_preserve IN PLS_INTEGER DEFAULT 2);
END;
/

CREATE OR REPLACE PUBLIC SYNONYM xl FOR pkg_dbg_xlogger;
rem GRANT EXECUTE ON xl TO PUBLIC;