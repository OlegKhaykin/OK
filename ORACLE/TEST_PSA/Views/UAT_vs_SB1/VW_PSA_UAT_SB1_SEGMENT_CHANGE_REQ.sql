CREATE OR REPLACE VIEW vw_psa_uat_sb1_segment_change_req AS
WITH
  -- 19-Jan-2021,Sunil Nando: created UAT test view for psa_segment_change_requests table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid,
      psr.control_id,
      psr.sub_segment_cd,
      psr.segment_cd,
      TRUNC(psr.effective_start_dt)  AS effective_start_dt,
      psr.status,
      psr.comments 
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ahmadmin.psa_segment_change_requests         psr
      ON psr.psuid = psl.psuid
  ),
  old_op AS
  (
    SELECT --+ materialize
      psl.psuid,
      psr.control_id,
      psr.sub_segment_cd,
      psr.segment_cd,
      TRUNC(psr.effective_start_dt)  AS effective_start_dt,
      psr.status,
      psr.comments 
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ahmadmin.psa_segment_change_requests@sb1     psr
      ON psr.psuid = psl.psuid
  )
SELECT
  'psa_segment_change_requests : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'psa_segment_change_requests : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_sb1_segment_change_req TO deployer, ods_dml;