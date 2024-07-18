CREATE OR REPLACE VIEW vw_psa_uat_sb1_pprd_tgtpln AS
WITH
  -- 04-Jan-2021,UAT-Test View R.Donakonda: created
  new_results AS
  (
    SELECT --+ materialize
      ppsl.psuid,pp.Productcd,ppt.TrgtPoplnMnemonicCD
    FROM vw_psa_plan_sponsor_list                                         ppsl 
    JOIN ahmadmin.supplier                                                sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.PurchasedProduct                                        pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductTargetPLN                               ppt
      ON ppt.PurchasedProductID = pp.PurchasedProductID 
  ),
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT
      ppsl.psuid,pp.Productcd,ppt.TrgtPoplnMnemonicCD
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
    JOIN ahmadmin.PurchasedProductTargetPLN@sb1                           ppt
      ON ppt.PurchasedProductID = pp.PurchasedProductID  
  )
SELECT
  'PurchasedProductTargetPLN : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'PurchasedProductTargetPLN : OLD minus NEW'  AS Compare,
  o.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) o;


GRANT SELECT ON vw_psa_uat_sb1_pprd_tgtpln TO deployer, ods_dml;
