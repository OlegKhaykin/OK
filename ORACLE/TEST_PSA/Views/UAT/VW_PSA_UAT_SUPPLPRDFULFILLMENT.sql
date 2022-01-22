CREATE OR REPLACE VIEW vw_psa_uat_supplprdfulfillment AS
WITH
  -- 06-Jan-2021,Sunil Nando: created UAT test view for SupplierProductFulfillment table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid,
      spf.settinglevelcd,
      spf.fulfillcentercd, 
      spf.targetpopulationcd, 
      spf.commtargetcd, 
      spf.commtypecd, 
      spf.commmethodcd,
      spf.activeflg  
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ahmadmin.Supplier                            sup
      ON sup.psuid = psl.psuid
    JOIN ods.SupplierOrganization                     so
      ON so.ahmsupplierID = sup.ahmsupplierID
    JOIN ods.SupplierProductFulfillment               spf
      ON spf.supplierorgid = so.supplierorgid
  ),
  old_op AS
  (
    SELECT --+ materialize
    DISTINCT
      psl.psuid,
      spf.settinglevelcd,
      spf.fulfillcentercd, 
      spf.targetpopulationcd, 
      spf.commtargetcd, 
      spf.commtypecd, 
      spf.commmethodcd,
      spf.activeflg 
    FROM vw_psa_plan_sponsor_list                                psl 
    JOIN ahmadmin.plansponsor@psa                                         ps 
      ON ps.plansponsoruniqueid = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@psa                              c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount@psa                                csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@psa                                     scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey
    JOIN ahmadmin.Supplier@psa                                            sup
      ON sup.supplierid = scx.SupplierID
    JOIN ods.SupplierOrganization@psa                                     so
      ON so.ahmsupplierID = sup.ahmsupplierID
    JOIN ods.SupplierProductFulfillment@psa                               spf
      ON spf.supplierorgid = so.supplierorgid
  )
SELECT
  'SupplierProductFulfillment : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'SupplierProductFulfillment : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_supplprdfulfillment TO deployer, ods_dml;