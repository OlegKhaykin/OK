CREATE OR REPLACE VIEW vw_psa_uat_insorgsuplrln_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.insuranceorgsupplierrelation table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.psuid, ins.*
    FROM psl                
    JOIN ahmadmin.supplier                       s 
      ON s.psuid = psl.psuid    
    JOIN ods.supplierorganization                so
      ON so.ahmsupplierid = s.ahmsupplierid    
    JOIN ods.insuranceorgsupplierrelation        ins
      ON ins.supplierid = so.supplierorgid
  ),     
  old_results AS
  (
    SELECT --+ materialize driving_site(ps)
    DISTINCT   
      psl.psuid, ins.*
    FROM psl                                                            
    JOIN ahmadmin.PlanSponsor@psa                                       ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@psa                            c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
    JOIN ahmadmin.ControlSuffixAccount@psa                              csa
      ON csa.PlansponsorControlInfoSKEY = c.PlansponsorControlInfoSKEY
    JOIN ahmadmin.SupplierCSAXREF@psa                                   scx
      ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
    JOIN ahmadmin.supplier@psa                                          s
      ON s.SupplierID = scx.SupplierID 
    JOIN ods.supplierorganization@psa                                   so
      ON so.ahmsupplierid = s.ahmsupplierid                             
    JOIN ods.insuranceorgsupplierrelation@psa                           ins
      ON ins.supplierid = so.supplierorgid
  )
SELECT 'INSURANCEORGSUPPLIERRELATION : NEW'  AS Compare,  n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'INSURANCEORGSUPPLIERRELATION : OLD'  AS Compare,  o.* FROM (SELECT * FROM old_results) o;


GRANT SELECT ON vw_psa_uat_insorgsuplrln_dbg TO deployer, ods_dml;