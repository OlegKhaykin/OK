CREATE OR REPLACE VIEW vw_psa_uat_sb1_supplplnspnsrlnshp_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.supplierplansponsrrelationship table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.psuid, srln.*
    FROM psl                                     
    JOIN ods.plansponsor                         ps
      ON ps.psuid = psl.psuid                            
    JOIN ods.supplierplansponsrrelationship      srln 
      ON srln.plansponsorinstanceid = ps.plansponsorinstanceid
  ),      
  old_results AS
  (
   SELECT --+ materialize
     psl.psuid, srln.*
   FROM psl                             
   JOIN ods.plansponsor@sb1                      ps 
     ON ps.psuid = psl.psuid                            
   JOIN ods.supplierplansponsrrelationship@sb1   srln
     ON srln.plansponsorinstanceid = ps.plansponsorinstanceid
  )
SELECT 'SupplierPlansponsrRelationship : NEW'  AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'SupplierPlansponsrRelationship : OLD'  AS Compare, o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_sb1_supplplnspnsrlnshp_dbg TO deployer, ods_dml;