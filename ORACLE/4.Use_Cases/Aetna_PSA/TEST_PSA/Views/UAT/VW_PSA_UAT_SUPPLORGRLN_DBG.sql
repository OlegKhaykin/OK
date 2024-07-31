CREATE OR REPLACE VIEW vw_psa_uat_supplorgrln_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.supplierorgrelation table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.PSUID, sog.*
    FROM psl                                      
    JOIN ahmadmin.supplier                        s 
      ON s.psuid = psl.psuid                     
    JOIN ahmadmin.supplierorgrelation             sog
      ON sog.supplierid = s.supplierid
  ),      
  old_results AS
  (
   SELECT --+ materialize driving_site(psl)
   DISTINCT
     psl.PSUID, sog.*
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
    JOIN ahmadmin.supplierorgrelation@psa                               sog
      ON sog.supplierid = s.supplierid
  )
SELECT 'Supplierorgrelation : NEW'  AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'Supplierorgrelation : OLD'  AS Compare, n.* FROM (SELECT * FROM old_results) n;

GRANT SELECT ON vw_psa_uat_supplorgrln_dbg TO deployer, ods_dml;