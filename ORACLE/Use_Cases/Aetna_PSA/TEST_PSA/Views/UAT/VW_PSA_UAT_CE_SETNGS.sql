CREATE OR REPLACE VIEW vw_psa_uat_ce_setngs AS
WITH
  -- 04-Jan-2021, R.Donakonda: created
  new_results AS
  (
    SELECT --+ materialize
      ppsl.psuid,pp.productcd,ce.calloutcenterid,ce.supplierrollupflg,
      ce.coloringthresholdnumber,ce.ccageddaysnumber,ce.inboundcaseopenflg,
      ce.priorityprintflg,ce.phasedccimplementationflg,TRUNC(ce.phaseoneenddt),
      ce.communicationchannelid,ce.qienvelopetypeid
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
      ppsl.psuid,pp.productcd,ce.calloutcenterid,ce.supplierrollupflg,
      ce.coloringthresholdnumber,ce.ccageddaysnumber,ce.inboundcaseopenflg,
      ce.priorityprintflg,ce.phasedccimplementationflg,TRUNC(ce.phaseoneenddt),
      ce.communicationchannelid,ce.qienvelopetypeid
    FROM vw_psa_plan_sponsor_list                                         ppsl
    JOIN ahmadmin.plansponsor@psa                                         ps 
      ON ps.plansponsoruniqueid = ppsl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@psa                              c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount @psa                               csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@psa                                     scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey
    JOIN ahmadmin.Supplier@psa                                            sup
      ON sup.supplierid = scx.SupplierID
    JOIN ahmadmin.PurchasedProduct@psa                                    pp
      ON pp.SupplierID = sup.SupplierID  
    JOIN ahmadmin.PurchasedProductSettings@psa                            pps
      ON pps.PurchasedProductID = pp.PurchasedProductID
    JOIN ahmadmin.CESettings@psa                                          ce
      ON ce.PurchasedProductSettingsSKEY = pps.PurchasedProductSettingsSKEY  
  )
SELECT
  'CESettings : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'CESettings : OLD minus NEW'  AS Compare,
  o.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) o;

GRANT SELECT ON vw_psa_uat_ce_setngs TO deployer, ods_dml;
