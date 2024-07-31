BEGIN
  FOR r IN
  (
    SELECT d.table_name
    FROM (SELECT 'CNF_TESTS' table_name FROM dual) d
    LEFT JOIN dba_tables t ON t.owner = 'TEST_PSA' AND t.table_name = d.table_name
    WHERE t.table_name IS NULL
  )
  LOOP
    EXECUTE IMMEDIATE '
CREATE TABLE test_psa.cnf_tests
(
  test_case   VARCHAR2(20)  NOT NULL,
  test_num    VARCHAR2(8)   NOT NULL,
  psuid       VARCHAR2(20)  NOT NULL,
  batch_skey  INTEGER       NOT NULL,
  proc_id     INTEGER,
  CONSTRAINT pk_cnf_tests PRIMARY KEY (test_case, test_num) USING INDEX TABLESPACE users
)
TABLESPACE users';

    EXECUTE IMMEDIATE 'GRANT SELECT ON test_psa.cnf_tests TO PUBLIC';
    EXECUTE IMMEDIATE 'GRANT ALL ON test_psa.cnf_tests TO AHMAdmin_dml, ods_dml';
  END LOOP;
  
  FOR r IN
  (
    SELECT t.owner, t.table_name, 'IX_CNF_TESTS_PROC_ID' index_name
    FROM dba_tables           t
    LEFT JOIN dba_indexes     i 
      ON i.owner = t.owner AND i.table_name = t.table_name AND i.index_name = 'IX_CNF_TESTS_PROC_ID' 
    WHERE t.owner = 'TEST_PSA' AND t.table_name = 'CNF_TESTS' AND i.table_name IS NULL
  )
  LOOP
    EXECUTE IMMEDIATE 'CREATE INDEX '||r.index_name||' ON '||r.table_name||'(proc_id) TABLESPACE users';
  END LOOP; 
END;
/
