BEGIN
  FOR r IN
  (
    SELECT table_name FROM dba_tables
    WHERE table_name = 'TMP_ALL_COLUMNS'
    AND owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
  )
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||r.table_name||' PURGE';
  END LOOP;
END;
/

CREATE GLOBAL TEMPORARY TABLE tmp_all_columns
(
  side         CHAR(3) CONSTRAINT chk_col_side CHECK(side IN ('SRC','TGT')),
  owner        VARCHAR2(30) NOT NULL,
  table_name   VARCHAR2(30) NOT NULL,
  column_id    NUMBER       NOT NULL,
  column_name  VARCHAR2(30) NOT NULL,
  data_type    VARCHAR2(30) NOT NULL,
  uk           CHAR(1)      NOT NULL,
  nullable     CHAR(1)      NOT NULL,
  CONSTRAINT pk_tmp_all_columns PRIMARY KEY(side, column_name)
)
ON COMMIT DELETE ROWS;
