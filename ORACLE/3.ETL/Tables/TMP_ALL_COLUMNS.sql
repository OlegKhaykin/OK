BEGIN
  FOR r IN
  (
    SELECT d.table_name
    FROM (SELECT 'TMP_ALL_COLUMNS' table_name FROM dual) d 
    LEFT JOIN user_tables t ON t.table_name = d.table_name
    WHERE t.table_name IS NULL 
  )
  LOOP
    EXECUTE IMMEDIATE
   'CREATE GLOBAL TEMPORARY TABLE tmp_all_columns
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
    ON COMMIT DELETE ROWS';
  END LOOP;
END;
/
