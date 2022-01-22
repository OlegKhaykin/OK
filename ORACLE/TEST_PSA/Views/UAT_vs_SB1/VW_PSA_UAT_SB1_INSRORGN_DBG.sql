CREATE OR REPLACE VIEW vw_psa_uat_sb1_insrorgn_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.insuranceorganization table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.PSUID,io.*
    FROM psl              
    JOIN ahmadmin.supplier                        s 
      ON s.psuid = psl.psuid                     
    JOIN ahmadmin.supplierorgrelation             so
      ON so.supplierid = s.supplierid             
    JOIN ods.insuranceorganization                io 
      ON io.insuranceorgid = so.orgid
  ),      
  old_results AS
  (
    SELECT --+ materialize driving_site(ps)
    DISTINCT
      psl.PSUID, io.*
    FROM psl                                     
    JOIN ahmadmin.PlanSponsor@sb1                                       ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                            c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
    JOIN ahmadmin.ControlSuffixAccount@sb1                              csa
      ON csa.PlansponsorControlInfoSKEY = c.PlansponsorControlInfoSKEY
    JOIN ahmadmin.SupplierCSAXREF@sb1                                   scx
      ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
    JOIN ahmadmin.supplier@sb1                                          s
      ON s.SupplierID = scx.SupplierID 
    JOIN ahmadmin.supplierorgrelation@sb1                               so
      ON so.supplierid = s.SupplierID
    JOIN ods.insuranceorganization@sb1                                  io 
      ON io.insuranceorgid = so.orgid
  )
SELECT 'INSURANCEORGANIZATION : NEW'  AS Compare,  n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'INSURANCEORGANIZATION : OLD'  AS Compare,  o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_sb1_insrorgn_dbg TO deployer, ods_dml;