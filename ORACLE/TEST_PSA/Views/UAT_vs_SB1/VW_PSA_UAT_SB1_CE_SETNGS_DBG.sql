CREATE OR REPLACE VIEW vw_psa_uat_sb1_ce_setngs_dbg AS
WITH
  -- 03-Mar-2021,R.Donakonda: created UAT test dbg view for CESettings table
  new_results AS
  (
    SELECT --+ materialize
      ppsl.psuid,ce.*
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.supplier                                                 sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.PurchasedProduct                                         pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductSettings                                 pps
      ON pps.PurchasedProductID = pp.PurchasedProductID 
    JOIN ahmadmin.CESettings                                               ce
      ON ce.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY         
  ),
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT
      ppsl.psuid,ce.*
    FROM vw_psa_plan_sponsor_list                                         ppsl
    JOIN ahmadmin.plansponsor@sb1                                         ps 
      ON ps.plansponsoruniqueid = ppsl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                              c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount @sb1                               csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@sb1                                     scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey
    JOIN ahmadmin.Supplier@sb1                                            sup
      ON sup.supplierid = scx.SupplierID
    JOIN ahmadmin.PurchasedProduct@sb1                                    pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductSettings@sb1                            pps
      ON pps.PurchasedProductID = pp.PurchasedProductID
    JOIN ahmadmin.CESettings@sb1                                          ce
      ON ce.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY  
  )
SELECT 'CESettings : NEW' AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'CESettings : OLD' AS Compare, o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_sb1_ce_setngs_dbg TO deployer, ods_dml;
