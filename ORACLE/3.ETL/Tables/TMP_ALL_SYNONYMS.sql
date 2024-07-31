BEGIN
  FOR r IN
  (
    SELECT d.table_name
    FROM (SELECT 'TMP_ALL_SYNONYMS' table_name FROM dual) d 
    LEFT JOIN user_tables t ON t.table_name = d.table_name
    WHERE t.table_name IS NULL 
  )
  LOOP
    EXECUTE IMMEDIATE
   'CREATE GLOBAL TEMPORARY TABLE tmp_all_synonyms
    (    
      owner         VARCHAR2(128),
      synonym_name  VARCHAR2(128),
      table_owner   VARCHAR2(128),
      table_name    VARCHAR2(128),
      db_link       VARCHAR2(128),
      CONSTRAINT pk_all_synonyms PRIMARY KEY(owner, synonym_name)
    ) ON COMMIT PRESERVE ROWS';
  END LOOP;
END;
/
