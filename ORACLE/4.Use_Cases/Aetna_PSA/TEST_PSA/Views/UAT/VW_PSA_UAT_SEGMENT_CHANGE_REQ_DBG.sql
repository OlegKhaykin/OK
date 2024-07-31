CREATE OR REPLACE VIEW vw_psa_uat_segment_change_req_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for psa_segment_change_requests table
  new_op AS
  (
    SELECT --+ materialize
      psr.*
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ahmadmin.psa_segment_change_requests         psr
      ON psr.psuid = psl.psuid
  ),
  old_op AS
  (
    SELECT --+ materialize
      psr.*
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ahmadmin.psa_segment_change_requests@psa     psr
      ON psr.psuid = psl.psuid
  )
SELECT 'psa_segment_change_requests : NEW'  AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'psa_segment_change_requests : OLD'  AS Compare, o.* FROM (SELECT * FROM old_op) o;

GRANT SELECT ON vw_psa_uat_segment_change_req_dbg TO deployer, ods_dml;