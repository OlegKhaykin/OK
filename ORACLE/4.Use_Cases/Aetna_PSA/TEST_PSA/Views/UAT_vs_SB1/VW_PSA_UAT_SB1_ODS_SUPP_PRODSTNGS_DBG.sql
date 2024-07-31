CREATE OR REPLACE VIEW vw_psa_uat_sb1_ods_supp_prodstngs_dbg AS
WITH
  -- 03-Mar-2021,R.Donakonda: created UAT test dbg view for ODS.Supplierproductsettings table
  new_results AS
  (
    SELECT --+ materialize
      s.psuid,
      Control_Cd,
      Suffix_Cd,
      Account_Cd,
      Plan_Cd,
      spr.*
    FROM ODS.Supplierproductsettings               spr
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
      p.PlanSponsorUniqueId AS PSUID,
      Controlid             AS Control_Cd,
      Suffixid              AS Suffix_Cd,
      Accountid             AS Account_Cd,
      Plansummarycd         AS Plan_Cd,
      spr.*
    FROM ODS.Supplierproductsettings@sb1               spr
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
SELECT 'ODS.SupplierProductSettings : NEW' AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'ODS.SupplierProductSettings : OLD' AS Compare,o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_sb1_ods_supp_prodstngs_dbg TO deployer, ods_dml, ahmadmin_read;
