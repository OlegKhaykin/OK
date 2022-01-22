CREATE OR REPLACE VIEW vw_psa_uat_ods_supp_prodreln_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.Supplierproductrelation table
  new_results AS
  (
    SELECT --+ materialize
    DISTINCT
      s.psuid, spr.*
    FROM ODS.Supplierproductrelation               spr
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
    DISTINCT
      p.PlanSponsorUniqueId AS PSUID, spr.*
    FROM ODS.Supplierproductrelation@psa               spr
    JOIN ODS.Supplierorganization@psa                  so
      ON so.supplierorgid = spr.supplierorgid
    JOIN ahmadmin.Supplier@psa                         s
      ON s.AHMSupplierID = so.AhmSupplierID
    JOIN ahmadmin.SupplierCSAXref@psa                  scx  
      ON scx.SupplierID = s.SupplierID
    JOIN ahmadmin.ControlSuffixAccount@psa             csa 
      ON csa.ControlSuffixAccountSkey = scx.ControlSuffixAccountSkey   
    JOIN ahmadmin.PlanSponsorControlInfo@psa           c 
      ON c.Plansponsorcontrolinfoskey = csa.Plansponsorcontrolinfoskey  
    JOIN ahmadmin.plansponsor@psa                      p 
      ON p.PlanSponsorSKEY = c.PlanSponsorSKEY 
    JOIN vw_psa_plan_sponsor_list                      ppsl
      ON ppsl.psuid = p.PlanSponsorUniqueId
  )
SELECT 'ODS.SupplierProductRelation : NEW' AS Compare,  n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'ODS.SupplierProductRelation : OLD' AS Compare,  o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_ods_supp_prodreln_dbg TO deployer, ods_dml;

