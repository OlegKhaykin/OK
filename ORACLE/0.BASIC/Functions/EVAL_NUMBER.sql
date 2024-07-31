CREATE OR REPLACE FUNCTION eval_number(p_string IN VARCHAR2) RETURN NUMBER AS
/*
  18-JUL-2024, Oleg Khaykin (OK): created.
*/
  ret NUMBER;
BEGIN
  EXECUTE IMMEDIATE 'BEGIN :ret := '||p_string||'; END;' USING OUT ret;
  RETURN ret;
END;
/

GRANT EXECUTE ON eval_number TO PUBLIC;
 