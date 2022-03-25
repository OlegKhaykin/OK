CREATE OR REPLACE FUNCTION tab_v256_length(p_coll tab_v256) RETURN PLS_INTEGER AS
BEGIN
  RETURN p_coll.count;
END;
/

GRANT EXECUTE ON tab_v256_length TO PUBLIC;