CREATE OR REPLACE VIEW vw_psa_uat_sb1_suppacpkg_xr_dbg AS
WITH
  -- 02-Mar-2021,R.Donakonda: created UAT test dbg view for SupplierAcctpackageXREF table
  new_results AS
  (
    SELECT --+ materialize
    DISTINCT
      ppsl.psuid,
      scx.AHMsupplierID,
      scx.acctpackageid,
      scx.phaseoneflg,
      scx.healtheventcommflg,
      scx.widgetonlyflg
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.supplier                                                 sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.PurchasedProduct                                         pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.SupplierAcctpackageXREF                                  scx
      ON scx.AHMsupplierID = sup.AHMsupplierID      
  ),
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT
      ppsl.psuid,
      scx.AHMsupplierID,
      scx.acctpackageid,
      scx.phaseoneflg,
      scx.healtheventcommflg,
      scx.widgetonlyflg
    FROM vw_psa_plan_sponsor_list                                         ppsl
    JOIN ahmadmin.plansponsor@sb1                                         ps 
      ON ps.plansponsoruniqueid = ppsl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                              c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount@sb1                                csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@sb1                                     scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey
    JOIN ahmadmin.Supplier@sb1                                            sup
      ON sup.supplierid = scx.SupplierID
    JOIN ahmadmin.PurchasedProduct@sb1                                    pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.SupplierAcctpackageXREF@sb1                             scx
      ON scx.AHMsupplierID = sup.AHMsupplierID    
  )
SELECT 'SupplierAcctpackageXREF : NEW'  AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'SupplierAcctpackageXREF : OLD'  AS Compare, o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_sb1_suppacpkg_xr_dbg TO deployer, ods_dml;
