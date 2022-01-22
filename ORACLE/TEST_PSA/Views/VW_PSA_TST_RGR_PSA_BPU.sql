CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_psa_bpu AS
WITH
  -- 07-Mar-2021, R.Donakonda : Modified ,added static value for active_until_dt if it equals to SYSDATE.
  -- 24-Feb-2021, OK: two colums - TEST_PROC_ID and REF_PROC_ID instead of one.
  -- 16-Feb-2021, OK: replaced multiple columns with BPU_CD, added columns ACTIVE_SINCE_DT and ACTIVE_UNTIL_DT. 
  -- 12-Feb-2021, R.Donakonda: modified.
  -- 10-Feb-2021, A.Kapoor: created. 
  res AS
  (
    SELECT --+ materialize
      t.COLUMN_VALUE                                                                                    AS result_type, 
      p.test_proc_id,
      p.ref_proc_id,
      bpu.bpu_cd,
      bpu.funding_type,
      bpu.active_since_dt,
      DECODE(bpu.active_until_dt - 1, TRUNC(bpu.Updated_TS), DATE '2001-01-01', bpu.active_until_dt)     AS active_until_dt
    FROM vw_psa_tst_rgr_processes       p 
    CROSS JOIN TABLE(tab_number(1, 2))  t       
    JOIN tst_rgr_psa_bpu                bpu
      ON bpu.proc_id = DECODE(t.COLUMN_VALUE, 1, p.test_proc_id, p.ref_proc_id)       
  ), 
  test_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, bpu_cd, funding_type, active_since_dt, active_until_dt
    FROM res       
    WHERE result_type = 1  
  ),
  ref_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, bpu_cd, funding_type, active_since_dt, active_until_dt
    FROM res       
    WHERE result_type = 2 
  )  
SELECT 'VW_PSA_TST_RGR_PSA_BPU: Ref. MINUS Test' compare, d.* FROM (SELECT * FROM ref_data MINUS SELECT * FROM test_data) d 
UNION ALL
SELECT 'VW_PSA_TST_RGR_PSA_BPU: Test MINUS Ref.' compare, d.* FROM (SELECT * FROM test_data MINUS SELECT * FROM ref_data) d;

GRANT SELECT ON vw_psa_tst_rgr_psa_bpu TO deployer, ods_dml, ahmadmin_read;
