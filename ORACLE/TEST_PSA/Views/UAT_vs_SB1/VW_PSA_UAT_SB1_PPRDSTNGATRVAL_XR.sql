CREATE OR REPLACE VIEW vw_psa_uat_sb1_pprdstngatrval_xr AS
WITH
  -- 04-Jan-2021,UAT-Test View R.Donakonda: created
  new_results AS
  (
    SELECT --+ materialize
      ppsl.psuid, pp.ProductCD, ppa.productattributexrefskey, 
      ppa.attributevalue, ppa.effstartdt, ppa.effenddt 
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.supplier                                                 sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.PurchasedProduct                                         pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductSettings                                 pps
      ON pps.PurchasedProductID = pp.PurchasedProductID 
    JOIN ahmadmin.PurchasedProdsettngATTRVALXREF                           ppa
      ON ppa.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY 
  ),     
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT
      ppsl.psuid, pp.ProductCD, ppa.productattributexrefskey, 
      ppa.attributevalue, ppa.effstartdt, ppa.effenddt 
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
    JOIN ahmadmin.PurchasedProductSettings@sb1                            pps
      ON pps.PurchasedProductID = pp.PurchasedProductID 
    JOIN ahmadmin.PurchasedProdsettngATTRVALXREF@sb1                      ppa
      ON ppa.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY 
  )
SELECT
  'PurchasedProdsettngATTRVALXREF : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'PurchasedProdsettngATTRVALXREF : OLD minus NEW'  AS Compare,
  o.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) o;

GRANT SELECT ON vw_psa_uat_sb1_pprdstngatrval_xr TO deployer, ods_dml;
