CREATE OR REPLACE VIEW vw_psa_uat_mstrsupplorg_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.mastersupplierorganization table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.psuid, mso.*
    FROM psl                                           
    JOIN ahmadmin.supplier                             s 
      ON s.psuid = psl.psuid    
    JOIN ods.mastersupplierorganization                mso
      ON mso.ahmsupplierid = s.ahmsupplierid
  ),      
  old_results AS
  (
   SELECT --+ materialize driving_site(ps)
   DISTINCT  psl.psuid, mso.*
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
SELECT 'MASTERSUPPLIERORGANIZATION : NEW'  AS Compare,  n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'MASTERSUPPLIERORGANIZATION : OLD'  AS Compare,  o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_mstrsupplorg_dbg TO deployer, ods_dml;
