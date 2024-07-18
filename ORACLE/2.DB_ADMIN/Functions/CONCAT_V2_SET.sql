CREATE OR REPLACE FUNCTION concat_v2_set
(
  p_cur IN SYS_REFCURSOR,
  p_sep IN VARCHAR2 DEFAULT ','
) RETURN CLOB 
  AUTHID CURRENT_USER
AS
  -- 18-JUL-2024, Oleg Khaykin (OK): created
  val  VARCHAR2(3900);
  ret  CLOB;
BEGIN
  LOOP
    FETCH p_cur INTO val;
    EXIT WHEN p_cur%NOTFOUND;

    ret := ret || val || p_sep;
  END LOOP;
  CLOSE p_cur;
  RETURN SUBSTR(ret, 1, LENGTH(ret) - LENGTH(p_sep));
END;
/

GRANT EXECUTE ON concat_v2_set TO PUBLIC;
