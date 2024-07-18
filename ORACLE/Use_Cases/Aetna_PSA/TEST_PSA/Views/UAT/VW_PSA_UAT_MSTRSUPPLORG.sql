CREATE OR REPLACE VIEW vw_psa_uat_mstrsupplorg AS
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
      mso.hdmsclientreferenceid                AS hdmsclientreferenceid,
      mso.orgnm                                AS orgnm,
      mso.sourcealternateuniqueid              AS sourcealternateuniqueid,
      TRUNC(mso.effectivestartdt)              AS effectivestartdt,
      TRUNC(mso.effectiveenddt)                AS effectiveenddt
    FROM psl                                           
    JOIN ahmadmin.supplier                             s 
      ON s.psuid = psl.psuid    
    JOIN ods.mastersupplierorganization                mso
      ON mso.ahmsupplierid = s.ahmsupplierid
  ),      
  old_results AS
  (
   SELECT --+ materialize driving_site(ps)
   DISTINCT
     psl.psuid,
     mso.hdmsclientreferenceid            AS hdmsclientreferenceid,
     mso.orgnm                            AS orgnm,
     mso.sourcealternateuniqueid          AS sourcealternateuniqueid,
     TRUNC(mso.effectivestartdt)          AS effectivestartdt,
     TRUNC(mso.effectiveenddt)            AS effectiveenddt
   FROM psl                                                             
   JOIN ahmadmin.PlanSponsor@psa                                        ps
     ON ps.PlanSponsorUniqueID = psl.psuid
   JOIN ahmadmin.PlanSponsorControlInfo@psa                             c
     ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
   JOIN ahmadmin.ControlSuffixAccount@psa                               csa
     ON csa.PlansponsorControlInfoSKEY = c.PlansponsorControlInfoSKEY
   JOIN ahmadmin.SupplierCSAXREF@psa                                    scx
     ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
   JOIN ahmadmin.supplier@psa                                           s
     ON s.SupplierID = scx.SupplierID            
   JOIN ods.mastersupplierorganization@psa                              mso
     ON mso.ahmsupplierid = s.ahmsupplierid
  )
SELECT
  'MASTERSUPPLIERORGANIZATION : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'MASTERSUPPLIERORGANIZATION : OLD minus NEW'  AS Compare,
  n.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) n;

GRANT SELECT ON vw_psa_uat_mstrsupplorg TO deployer, ods_dml;
