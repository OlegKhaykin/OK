CREATE OR REPLACE VIEW vw_psa_uat_sb1_ods_plansponsor AS
WITH
  -- 04-Jan-2020,UAT-Test View A.Kapoor: created
  new_results AS
  (
    SELECT --+ materialize
      ps.PSUID, 
      PSUName, 
      ClientSystemName
    FROM vw_psa_plan_sponsor_list ppsl
    JOIN ods.plansponsor                   ps 
      ON ps.psuid = ppsl.psuid
  ),      
  old_results AS
  (
    SELECT --+ materialize
      ps.PSUID, 
      PSUName, 
      ClientSystemName
    FROM vw_psa_plan_sponsor_list ppsl
    JOIN ods.plansponsor@sb1              ps 
      ON ps.psuid = ppsl.psuid
  )
SELECT
  'ODS.Plansponsor : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'ODS.Plansponsor : OLD minus NEW'  AS Compare,
  n.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) n;

GRANT SELECT ON vw_psa_uat_sb1_ods_plansponsor TO deployer, ods_dml, ahmadmin_read;