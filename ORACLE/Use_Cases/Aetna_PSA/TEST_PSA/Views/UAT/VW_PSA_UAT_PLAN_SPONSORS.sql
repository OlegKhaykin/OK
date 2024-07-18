CREATE OR REPLACE VIEW vw_psa_uat_plan_sponsors AS
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
      ps.plansponsornm,
      ps.orgid,
      ps.segment_name,
      ps.effectivestartdt,
      ps.effectiveenddt,
      ps.activeflg
    FROM psl
    JOIN ahmadmin.plansponsor                 ps
      ON ps.plansponsoruniqueid = psl.psuid
  ),
  old_data AS
  (
    SELECT --+ materialize driving_site(ps)
      psl.psuid,
      ps.plansponsornm,
      ps.orgid,
      ps.segment_name,
      ps.effectivestartdt,
      ps.effectiveenddt,
      ps.activeflg
    FROM psl
    JOIN ahmadmin.plansponsor@psa             ps
      ON ps.plansponsoruniqueid = psl.psuid
  )
SELECT 'PLANSPONSOR: NEW minus OLD' AS compare, nmo.*
FROM (SELECT * FROM new_data MINUS SELECT * FROM old_data) nmo
UNION ALL 
SELECT 'PLANSPONSOR: OLD minus NEW' AS compare, omn.*
FROM (SELECT * FROM old_data MINUS SELECT * FROM new_data) omn;

GRANT SELECT ON vw_psa_uat_plan_sponsors TO deployer, ods_dml, ahmadmin_read;