CREATE OR REPLACE FUNCTION eval_ytm_interval(p_string IN VARCHAR2) RETURN INTERVAL YEAR TO MONTH AS
/*
  18-JUL-2024, Oleg Khaykin (OK): created.
*/
  ret INTERVAL YEAR TO MONTH;
BEGIN
  EXECUTE IMMEDIATE 'BEGIN :ret := '||p_string||'; END;' USING OUT ret;
  RETURN ret;
END;
/
 
GRANT EXECUTE ON eval_ytm_interval TO PUBLIC;

