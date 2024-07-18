CREATE OR REPLACE VIEW vw_psa_uat_sb1_supplprdfulfillment AS
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
    JOIN ahmadmin.plansponsor@sb1                                         ps 
      ON ps.plansponsoruniqueid = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                              c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount@sb1                                csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@sb1                                     scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey
    JOIN ahmadmin.Supplier@sb1                                            sup
      ON sup.supplierid = scx.SupplierID
    JOIN ods.SupplierOrganization@sb1                                     so
      ON so.ahmsupplierID = sup.ahmsupplierID
    JOIN ods.SupplierProductFulfillment@sb1                               spf
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

GRANT SELECT ON vw_psa_uat_sb1_supplprdfulfillment TO deployer, ods_dml;