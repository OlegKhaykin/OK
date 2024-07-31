CREATE OR REPLACE VIEW vw_psa_uat_pprdofatrval_xr_dbg AS
WITH
  -- 03-Mar-2021,R.Donakonda: created UAT test dbg view for PurchasedProdoffngAttrvalXREF table
  new_results AS
  (
    SELECT --+ materialize
      ppsl.psuid, ppa.*
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.supplier                                                 sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.PurchasedProduct                                         pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductOFFERING                                 ppo
      ON ppo.PurchasedProductID = pp.PurchasedProductID 
    JOIN ahmadmin.PurchasedProdoffngAttrvalXREF                            ppa
      ON ppa.PurchasedProductOfferingSKEY = ppo.PurchasedProductOfferingSKEY 
  ),
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT
      ppsl.psuid, ppa.*
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
    JOIN ahmadmin.PurchasedProductOFFERING@psa                            ppo
      ON ppo.PurchasedProductID = pp.PurchasedProductID
    JOIN ahmadmin.PurchasedProdoffngAttrvalXREF@psa                       ppa
      ON ppa.PurchasedProductOfferingSKEY = ppo.PurchasedProductOfferingSKEY 
  )
SELECT 'PurchasedProdoffngAttrvalXREF: NEW' AS Compare, n.* FROM new_results n
UNION ALL
SELECT 'PurchasedProdoffngAttrvalXREF: OLD' AS Compare, o.* FROM old_results o;

GRANT SELECT ON vw_psa_uat_pprdofatrval_xr_dbg TO deployer, ods_dml;
