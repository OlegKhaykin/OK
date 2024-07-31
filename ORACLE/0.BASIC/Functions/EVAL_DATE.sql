CREATE OR REPLACE FUNCTION eval_date(p_string IN VARCHAR2) RETURN DATE AS
/*
  18-JUL-2024, Oleg Khaykin (OK): created.
*/
  ret DATE;
BEGIN
  EXECUTE IMMEDIATE 'BEGIN :ret := '||CASE
    WHEN REGEXP_LIKE(p_string, 'DATE', 'i') THEN p_string
    WHEN REGEXP_LIKE(p_string, 'TIMESTAMP', 'i') THEN 'TRUNC('||p_string||')'
    ELSE 'TO_DATE('''||p_string||''')' END ||'; END;' 
  USING OUT ret;
  
  RETURN ret;
END;
/

GRANT EXECUTE ON eval_date TO PUBLIC;
