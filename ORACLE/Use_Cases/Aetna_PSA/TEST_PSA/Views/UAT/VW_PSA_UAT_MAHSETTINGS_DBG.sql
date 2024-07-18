CREATE OR REPLACE VIEW vw_psa_uat_mahsettings_dbg AS
WITH
  -- 03-Mar-2021,R.Donakonda: created UAT test dbg view for MAHsettings table
  new_results AS
  (
    SELECT --+ materialize
     ppsl.psuid,ms.*
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.supplier                                                 sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.PurchasedProduct                                         pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductSettings                                 pps
      ON pps.PurchasedProductID = pp.PurchasedProductID 
    JOIN ahmadmin.MAHsettings                                              ms
      ON ms.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY  
  ),
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT  ppsl.psuid,ms.*
    FROM vw_psa_plan_sponsor_list                                         ppsl
    JOIN ahmadmin.plansponsor@psa                                         ps 
      ON ps.plansponsoruniqueid = ppsl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@psa                              c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount@psa                                csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@psa                                     scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey
    JOIN ahmadmin.Supplier@psa                                            sup
      ON sup.supplierid = scx.SupplierID
    JOIN ahmadmin.PurchasedProduct@psa                                    pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductSettings@psa                            pps
      ON pps.PurchasedProductID = pp.PurchasedProductID
    JOIN ahmadmin.MAHsettings@psa                                         ms
      ON ms.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY 
  )
SELECT 'MAHsettings : NEW' AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'MAHsettings : OLD' AS Compare, o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_mahsettings_dbg TO deployer, ods_dml;
