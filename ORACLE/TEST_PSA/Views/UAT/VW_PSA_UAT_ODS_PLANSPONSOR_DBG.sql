CREATE OR REPLACE VIEW vw_psa_uat_ods_plansponsor_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.plansponsor table
  new_results AS
  (
    SELECT --+ materialize
      ps.*
    FROM vw_psa_plan_sponsor_list ppsl
    JOIN ods.plansponsor                   ps 
      ON ps.psuid = ppsl.psuid
  ),      
  old_results AS
  (
    SELECT --+ materialize
      ps.*
    FROM vw_psa_plan_sponsor_list ppsl
    JOIN ods.plansponsor@psa              ps 
      ON ps.psuid = ppsl.psuid
  )
SELECT 'ODS.Plansponsor : NEW'  AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'ODS.Plansponsor : OLD'  AS Compare, o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_ods_plansponsor_dbg TO deployer, ods_dml;