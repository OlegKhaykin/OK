CREATE OR REPLACE VIEW vw_psa_uat_sb1_ods_supp_pgrmreln_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.Supplierprogramrelation table
  new_results AS
  (
    SELECT --+ materialize
    DISTINCT s.psuid, spgrm.*
    FROM ODS.Supplierprogramrelation               spgrm
    JOIN ods.SupplierProductRelation               spr
      ON spr.Supplierproductrelskey = spgrm.Supplierproductrelskey
    JOIN ODS.Supplierorganization                  so
      ON so.supplierorgid = spr.supplierorgid
    JOIN ahmadmin.Supplier                         s
      ON s.AHMSupplierID = so.AhmSupplierID
    JOIN vw_psa_plan_sponsor_list                  ppsl
      ON ppsl.psuid = s.psuid
    JOIN ahmadmin.psa_bpu_supplier_xref            pbx
      ON pbx.Supplier_ID = s.SupplierID
    JOIN ahmadmin.psa_benefit_provision_units      pbpu
      ON pbpu.bpu_skey = pbx.bpu_skey  
  ),      
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT p.PlanSponsorUniqueId AS PSUID, spgrm.*
    FROM ODS.Supplierprogramrelation@sb1               spgrm
    JOIN ods.SupplierProductRelation@sb1               spr
      ON spr.Supplierproductrelskey = spgrm.Supplierproductrelskey
    JOIN ODS.Supplierorganization@sb1                  so
      ON so.supplierorgid = spr.supplierorgid
    JOIN ahmadmin.Supplier@sb1                         s
      ON s.AHMSupplierID = so.AhmSupplierID
    JOIN ahmadmin.SupplierCSAXref@sb1                  scx  
      ON scx.SupplierID = s.SupplierID
    JOIN ahmadmin.ControlSuffixAccount@sb1             csa 
      ON csa.ControlSuffixAccountSkey = scx.ControlSuffixAccountSkey   
    JOIN ahmadmin.PlanSponsorControlInfo@sb1           c 
      ON c.Plansponsorcontrolinfoskey = csa.Plansponsorcontrolinfoskey  
    JOIN ahmadmin.plansponsor@sb1                      p 
      ON p.PlanSponsorSKEY = c.PlanSponsorSKEY 
    JOIN vw_psa_plan_sponsor_list                      ppsl
      ON ppsl.psuid = p.PlanSponsorUniqueId
  )
SELECT 'ODS.SupplierProgramRelation : NEW' AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'ODS.SupplierProgramRelation : OLD' AS Compare, o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_sb1_ods_supp_pgrmreln_dbg TO deployer, ods_dml;

