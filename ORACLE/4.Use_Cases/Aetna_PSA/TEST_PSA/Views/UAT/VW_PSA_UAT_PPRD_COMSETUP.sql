CREATE OR REPLACE VIEW vw_psa_uat_pprd_comsetup AS
WITH
  -- 04-Jan-2021,UAT Test view R.Donakonda: created
  new_results AS
  (
    SELECT --+ materialize
      ppsl.psuid,pp.productcd,ff.fulfillmentprodcommsetupskey,ff.activeflg 
    FROM vw_psa_plan_sponsor_list                                          ppsl
    JOIN ahmadmin.supplier                                                 sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.PurchasedProduct                                         pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductSettings                                 pps
      ON pps.PurchasedProductID = pp.PurchasedProductID 
    JOIN ahmadmin.PurchasedProductCommsetup                                ff
    ON ff.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY           
  ),
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT
      ppsl.psuid,pp.productcd,ff.fulfillmentprodcommsetupskey,ff.activeflg 
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
    JOIN ahmadmin.PurchasedProductCommsetup@psa                           ff
    ON ff.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY              
  )
SELECT
  'PurchasedProductCommsetup : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'PurchasedProductCommsetup : OLD minus NEW'  AS Compare,
  o.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) o;

GRANT SELECT ON vw_psa_uat_pprd_comsetup TO deployer, ods_dml;

