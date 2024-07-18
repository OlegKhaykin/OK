CREATE OR REPLACE FUNCTION eval_dts_interval(p_string IN VARCHAR2) RETURN INTERVAL DAY TO SECOND AS
/*
  18-JUL-2024, Oleg Khaykin (OK): created.
*/
  ret INTERVAL DAY TO SECOND;
BEGIN
  EXECUTE IMMEDIATE 'BEGIN :ret := '||p_string||'; END;' USING OUT ret;
  RETURN ret;
END;
/
 
GRANT EXECUTE ON eval_dts_interval TO PUBLIC;

