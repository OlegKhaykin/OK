CREATE OR REPLACE VIEW vw_psa_tst_rgr_processes AS
SELECT
  -- 15-Feb-2021, OK: used LEFT JOIN.
  -- 11-Feb-2021, OK: created.
  t.rnum, 
  t.proc_ID   AS test_proc_id,
  r.proc_ID   AS ref_proc_id
FROM
(
  SELECT ROWNUM rnum, TO_NUMBER(COLUMN_VALUE) proc_id
  FROM TABLE(split_string(psa.get_parameter('TEST_PROC_IDS')))
) t
LEFT JOIN
(
  SELECT ROWNUM rnum, TO_NUMBER(COLUMN_VALUE) proc_id
  FROM TABLE(split_string(psa.get_parameter('REFERENCE_PROC_IDS')))
) r
ON r.rnum = t.rnum;
 
GRANT SELECT ON vw_psa_tst_rgr_processes TO PUBLIC;