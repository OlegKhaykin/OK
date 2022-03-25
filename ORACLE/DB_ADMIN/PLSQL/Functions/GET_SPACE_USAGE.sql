CREATE OR REPLACE FUNCTION get_space_usage(p_schema IN VARCHAR2 DEFAULT NULL) RETURN PLS_INTEGER IS
  n_gb PLS_INTEGER;
BEGIN
  SELECT ROUND(SUM(bytes)/1048576) INTO n_gb
  FROM dba_segments
  WHERE owner = NVL(p_schema, SYS_CONTEXT('USERENV','CURRENT_SCHEMA'));
  
  RETURN n_gb;
END;
/

GRANT EXECUTE ON get_space_usage TO PUBLIC;