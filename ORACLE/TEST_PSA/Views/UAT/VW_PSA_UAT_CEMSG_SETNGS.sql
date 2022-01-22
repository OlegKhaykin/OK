CREATE OR REPLACE VIEW vw_psa_uat_cemsg_setngs AS
WITH
  -- 04-Jan-2021, R.Donakonda: created
  new_results AS
  (
    SELECT --+ materialize
      ppsl.psuid, pp.productcd, cems.languageid,
      cems.lettertemplateid, cems.memberproviderid,
      cems.memberminletterage,cems.envelopetypeid,
      cems.timelagdaysnumber, cems.secondaryproviderletterflg,
      cems.labmonitoringccmemberonlyflg
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.supplier                                                 sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.PurchasedProduct                                         pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductSettings                                 pps
      ON pps.PurchasedProductID = pp.PurchasedProductID 
    JOIN ahmadmin.CEMessagingSettings                                      cems
      ON cems.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY     
  ),
  old_results AS
  (
    SELECT --+ materialize
    DISTINCT
      ppsl.psuid, pp.productcd, cems.languageid,
      cems.lettertemplateid, cems.memberproviderid,
      cems.memberminletterage,cems.envelopetypeid,
      cems.timelagdaysnumber, cems.secondaryproviderletterflg,
      cems.labmonitoringccmemberonlyflg
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
    JOIN ahmadmin.CEMessagingSettings@psa                                 cems
      ON cems.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY   
  )
SELECT
  'CEMessagingSettings : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'CEMessagingSettings : OLD minus NEW'  AS Compare,
  o.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) o;

GRANT SELECT ON vw_psa_uat_cemsg_setngs TO deployer, ods_dml;
