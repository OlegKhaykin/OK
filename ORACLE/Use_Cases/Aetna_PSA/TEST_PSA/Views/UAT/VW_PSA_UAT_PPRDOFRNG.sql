CREATE OR REPLACE VIEW vw_psa_uat_pprdofrng AS
WITH
  -- 04-Jan-2021,UAT Test view R.Donakonda: created
  new_results AS
  (
    SELECT --+ materialize
      ppsl.psuid,po.productcd,po.offeringtypeid,po.offeringid,po.productofferinglivedt,
      po.productofferingterminationdt,po.minrequiredage,po.thresholdscore,po.userinterfacemodecd
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.supplier                                                 sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.PurchasedProduct                                         pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductOffering                                 po
      ON po.PurchasedProductID = pp.PurchasedProductID   
  ),
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT
      ppsl.psuid,po.productcd,po.offeringtypeid,po.offeringid,po.productofferinglivedt,
      po.productofferingterminationdt,po.minrequiredage,po.thresholdscore,po.userinterfacemodecd
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
    JOIN ahmadmin.PurchasedProductOffering@psa                            po
      ON po.PurchasedProductID = pp.PurchasedProductID  
  )
SELECT
  'PurchasedProductOffering : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'PurchasedProductOffering : OLD minus NEW'  AS Compare,
  o.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) o;

GRANT SELECT ON vw_psa_uat_pprdofrng TO deployer, ods_dml;
