CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_plan_sponsor AS
WITH
  -- 07-Mar-2021, R.Donakonda : Modified. 
  -- 24-Feb-2021, OK: two colums - TEST_PROC_ID and REF_PROC_ID instead of one.
  -- 11-Feb-2021, OK: fixed.
  -- 10-Feb-2021, A.Kapoor: created.
  res AS
  (
    SELECT --+ materialize
      t.COLUMN_VALUE                                                                      AS result_type,    
      p.test_proc_id,
      p.ref_proc_id,
      ps.plansponsoruniqueID,
      ps.plansponsornm,
      ps.orgid,
      ps.segment_name,
      ps.effectivestartdt,
      CASE WHEN ps.effectiveenddt = TRUNC(ps.UpdatedDT) THEN DATE '0001-01-01' ELSE ps.effectiveenddt END effectiveenddt,
      ps.activeflg
    FROM vw_psa_tst_rgr_processes       p 
    CROSS JOIN TABLE(tab_number(1, 2))  t     
    JOIN tst_rgr_plan_sponsor           ps
      ON ps.proc_id = DECODE(t.COLUMN_VALUE, 1, p.test_proc_id, p.ref_proc_id)      
  ), 
  test_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, plansponsoruniqueID, plansponsornm, orgid,
      segment_name, effectivestartdt, effectiveenddt, activeflg
    FROM res
    WHERE result_type = 1
  ),
  ref_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, plansponsoruniqueID, plansponsornm, orgid,
      segment_name, effectivestartdt, effectiveenddt, activeflg
    FROM res
    WHERE result_type = 2
  )  
SELECT 'VW_PSA_TST_RGR_PLAN_SPONSOR: Test MINUS Ref.' compare, d.* FROM (SELECT * FROM test_data MINUS SELECT * FROM ref_data) d
UNION ALL
SELECT 'VW_PSA_TST_RGR_PLAN_SPONSOR: Ref. MINUS Test' compare, d.* FROM (SELECT * FROM ref_data MINUS SELECT * FROM test_data) d; 

GRANT SELECT ON vw_psa_tst_rgr_plan_sponsor TO deployer, ods_dml, ahmadmin_read;
