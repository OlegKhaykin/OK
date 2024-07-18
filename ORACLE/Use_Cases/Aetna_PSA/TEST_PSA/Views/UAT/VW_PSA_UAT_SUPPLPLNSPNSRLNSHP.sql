CREATE OR REPLACE VIEW vw_psa_uat_supplplnspnsrlnshp AS
WITH
  -- 15-Jan-2021,Sunil Nando: Formatted and did some minor changes
  -- 12-Jan-2021,Review comments incorporated : Srinivas MR : modified
  -- 06-Jan-2020,UAT-Test View Srinivas MR : created
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.psuid,
      TRUNC(srln.effectivestartdt)               AS effectivestartdt,
      TRUNC(srln.effectiveenddt)                 AS effectiveenddt
    FROM psl                                     
    JOIN ods.plansponsor                         ps
      ON ps.psuid = psl.psuid                            
    JOIN ods.supplierplansponsrrelationship      srln 
      ON srln.plansponsorinstanceid = ps.plansponsorinstanceid
  ),      
  old_results AS
  (
   SELECT --+ materialize
     psl.psuid,
     TRUNC(srln.effectivestartdt)               AS effectivestartdt,
     TRUNC(srln.effectiveenddt)                 AS effectiveenddt
   FROM psl                             
   JOIN ods.plansponsor@psa                      ps 
     ON ps.psuid = psl.psuid                            
   JOIN ods.supplierplansponsrrelationship@psa   srln
     ON srln.plansponsorinstanceid = ps.plansponsorinstanceid
  )
SELECT
  'SupplierPlansponsrRelationship : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'SupplierPlansponsrRelationship : OLD minus NEW'  AS Compare,
  o.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) o;

GRANT SELECT ON vw_psa_uat_supplplnspnsrlnshp TO deployer, ods_dml;