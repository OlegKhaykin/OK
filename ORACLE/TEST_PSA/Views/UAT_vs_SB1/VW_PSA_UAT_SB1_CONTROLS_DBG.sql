CREATE OR REPLACE VIEW vw_psa_uat_sb1_controls_dbg AS 
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for psa_controls table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_data AS
  (
    SELECT --+ materialize
      psl.psuid,
      c.control_cd,
      c.control_name,
      c.field_office,
      c.contract_state,
      c.segment_cd,
      c.sub_segment_cd,
      TRUNC(c.segment_dt) AS segment_dt
    FROM psl
    JOIN ahmadmin.psa_controls c
      ON c.psuid = psl.psuid
  ),
  old_data AS
  (
    SELECT --+ materialize driving_site(ps)
      psl.psuid,
      c.controlid                                     AS control_cd, 
      c.controlnm                                     AS control_name,
      c.fieldoffice                                   AS field_office,
      c.contractstate                                 AS contract_state,
      c.segmentcd                                     AS segment_cd,
      c.subsegmentcd                                  AS sub_segment_cd,
      TRUNC(c.segment_effective_dt)                   AS segment_dt
    FROM psl
    JOIN ahmadmin.PlanSponsor@sb1               ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1    c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
  )
SELECT 'PSA_CONTROLS' AS compare, n.* FROM (SELECT * FROM new_data) n
UNION ALL
SELECT 'PLANSPONSORCONTROLINFO' AS compare, o.* FROM (SELECT * FROM old_data) o;

GRANT SELECT ON vw_psa_uat_sb1_controls_dbg TO deployer, ods_dml, ahmadmin_read;