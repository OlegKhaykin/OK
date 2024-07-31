SELECT COLUMN_VALUE hash_value FROM TABLE(hash_source_code('OK', 'PACKAGE BODY', 'PKG_ETL_UTILS')); 

SELECT ROWNUM portion, COLUMN_VALUE hash_value FROM TABLE(hash_source_code('OK', 'PACKAGE BODY', 'PKG_ETL_UTILS', 100));

SELECT ROWNUM portion, COLUMN_VALUE hash_value FROM TABLE(hash_source_code('OK', 'PACKAGE BODY', 'PKG_ETL_UTILS', 10, 501, 600)); 

SELECT
  line, text
  , lengthb(text) text_length
  , md5_hash(text) hash_value
  --, utl_raw.cast_to_raw(text) raw_value
FROM user_source WHERE type = 'PACKAGE BODY' AND name = 'PKG_ETL_UTILS' AND line BETWEEN 541 AND 550 ORDER BY line;
