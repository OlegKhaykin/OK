CREATE OR REPLACE VIEW vw_psa_uat_controls AS 
WITH
 -- 05-Jan-2021, O.Khaykin: created.
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
    JOIN ahmadmin.PlanSponsor@psa               ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@psa    c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
  )
SELECT 'PSA_CONTROLS minus PLANSPONSORCONTROLINFO' compare, nmo.*
FROM (SELECT * FROM new_data MINUS SELECT * FROM old_data) nmo
UNION ALL
SELECT 'PLANSPONSORCONTROLINFO minus PSA_CONTROLS' compare, omn.*
FROM (SELECT * FROM old_data MINUS SELECT * FROM new_data) omn;

GRANT SELECT ON vw_psa_uat_controls TO deployer, ods_dml, ahmadmin_read;