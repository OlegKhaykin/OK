CREATE OR REPLACE VIEW vw_psa_uat_sb1_ods_supp_mgmt_dbg AS
WITH
 -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.suppliermanagement table
  new_results AS
  (
    SELECT --+ materialize
      s.PsuiD, sm.*
    FROM ods.suppliermanagement               sm
    JOIN ahmadmin.Supplier                    s
      ON s.AHMSupplierID = sm.AHMSupplierID
    JOIN vw_psa_plan_sponsor_list             ppsl
      ON ppsl.psuid = s.psuid
  ),      
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT p.PlanSponsorUniqueId AS PsuiD, sm.*
    FROM Ods.Suppliermanagement@sb1                      sm
    JOIN ahmadmin.Supplier@sb1                           s
      ON s.AHMSupplierID = sm.AHMSupplierID
    JOIN ahmadmin.SupplierCSAXref@sb1                    scx  
      ON scx.SupplierID = s.SupplierID
    JOIN ahmadmin.ControlSuffixAccount@sb1               csa 
      ON csa.ControlSuffixAccountSkey = scx.ControlSuffixAccountSkey   
    JOIN ahmadmin.PlanSponsorControlInfo@sb1             c 
      ON c.Plansponsorcontrolinfoskey = csa.Plansponsorcontrolinfoskey  
    JOIN ahmadmin.plansponsor@sb1                        p 
      ON p.PlanSponsorSKEY = c.PlanSponsorSKEY 
    JOIN vw_psa_plan_sponsor_list                        ppsl
      ON ppsl.psuid = p.PlanSponsorUniqueId
  )
SELECT 'ODS.SupplierManagement : NEW'  AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'ODS.SupplierManagement : OLD'  AS Compare, n.* FROM (SELECT * FROM old_results) n;

GRANT SELECT ON vw_psa_uat_sb1_ods_supp_mgmt_dbg TO deployer, ods_dml;

