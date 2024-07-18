CREATE OR REPLACE VIEW vw_psa_uat_plan_sponsors_dbg AS
WITH
  -- 03-Mar-2021,R.Donakonda: created UAT test dbg view for Plansponsor table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_data AS
  (
    SELECT --+ materialize
      ps.plansponsorskey, ps.orgid, ps.plansponsoruniqueid, ps.plansponsornm,
      ps.effectivestartdt, ps.effectiveenddt, ps.activeflg,
      ps.inserteddt, ps.insertedby, ps.updateddt, ps.updatedby,
      ps.segment_name
    FROM psl
    JOIN ahmadmin.plansponsor                 ps
      ON ps.plansponsoruniqueid = psl.psuid
  ),
  old_data AS
  (
    SELECT --+ materialize driving_site(ps)
      ps.plansponsorskey, ps.orgid, ps.plansponsoruniqueid, ps.plansponsornm,
      ps.effectivestartdt, ps.effectiveenddt, ps.activeflg,
      ps.inserteddt, ps.insertedby, ps.updateddt, ps.updatedby,
      ps.segment_name
    FROM psl
    JOIN ahmadmin.plansponsor@psa             ps
      ON ps.plansponsoruniqueid = psl.psuid
  )
SELECT 'PLANSPONSOR: NEW' AS compare, n.* FROM (SELECT * FROM new_data) n
UNION ALL 
SELECT 'PLANSPONSOR: OLD' AS compare, o.* FROM (SELECT * FROM old_data) o;

GRANT SELECT ON vw_psa_uat_plan_sponsors_dbg TO deployer, ods_dml, ahmadmin_read;