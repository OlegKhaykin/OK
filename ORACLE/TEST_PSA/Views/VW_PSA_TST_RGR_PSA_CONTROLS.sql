CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_psa_controls AS
WITH
  -- 15-Mar-2021, R.Donakonda : Modified , Added case statement for segment_dt
  -- 07-Mar-2021, R.Donakonda : Modified ,added static value for segment_dt,active_until_dt if it equals to SYSDATE.
  -- 24-Feb-2021, OK: two colums - TEST_PROC_ID and REF_PROC_ID instead of one.
  -- 16-Feb-2021, OK: added columns PSUID, ACTIVE_SINCE_DT, ACTIVE_UNTIL_DT.
  -- 12-Feb-2021: Sunil Nando: Modified
  -- 10-Feb-2021: A.Kapoor: created.    
  res AS
  (
    SELECT --+ materialize
      t.COLUMN_VALUE                                                                              AS result_type,    
      p.test_proc_id,
      p.ref_proc_id,
      c.psuid,
      c.control_cd,
      c.control_name,
      c.field_office,
      c.contract_state,
      c.segment_cd,
      c.sub_segment_cd,
      CASE 
       WHEN c.segment_dt = TRUNC(c.Updated_TS) OR c.segment_dt - 1  = TRUNC(c.Updated_TS)
        THEN DATE '2001-01-01'
       ELSE c.segment_dt
      END                                                                                         AS segment_dt,      
      c.active_since_dt,
      DECODE(c.active_until_dt -1, TRUNC(c.Updated_TS), DATE '2001-01-01', c.active_until_dt)     AS active_until_dt
    FROM vw_psa_tst_rgr_processes       p
    CROSS JOIN TABLE(tab_number(1, 2))  t     
    JOIN tst_rgr_psa_controls           c
      ON c.proc_id = DECODE(t.COLUMN_VALUE, 1, p.test_proc_id, p.ref_proc_id)    
  ), 
  test_data AS
  (
 	  SELECT --+ materialize
      test_proc_id, ref_proc_id, psuid, control_cd, control_name,
      field_office, contract_state, segment_cd, sub_segment_cd,
      segment_dt, active_since_dt, active_until_dt
    FROM res       
    WHERE result_type = 1
  ),
  ref_data AS
  (
 	  SELECT --+ materialize
      test_proc_id, ref_proc_id, psuid, control_cd, control_name,
      field_office, contract_state, segment_cd, sub_segment_cd,
      segment_dt, active_since_dt, active_until_dt
    FROM res       
    WHERE result_type = 2
  )    
SELECT 'VW_PSA_TST_RGR_PSA_CONTROLS: Test MINUS Ref.' compare, d.* FROM (SELECT * FROM test_data MINUS SELECT * FROM ref_data) d
UNION ALL
SELECT 'VW_PSA_TST_RGR_PSA_CONTROLS: Ref. MINUS Test' compare, d.* FROM (SELECT * FROM ref_data MINUS SELECT * FROM test_data) d;

GRANT SELECT ON vw_psa_tst_rgr_psa_controls TO deployer, ods_dml, ahmadmin_read;