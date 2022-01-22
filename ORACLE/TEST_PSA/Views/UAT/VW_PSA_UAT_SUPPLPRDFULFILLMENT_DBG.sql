CREATE OR REPLACE VIEW vw_psa_uat_supplprdfulfillment_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.SupplierProductFulfillment table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid, spf.*
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
    DISTINCT  psl.psuid, spf.* 
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
SELECT 'SupplierProductFulfillment : NEW'  AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'SupplierProductFulfillment : OLD'  AS Compare, o.* FROM (SELECT * FROM old_op) o;

GRANT SELECT ON vw_psa_uat_supplprdfulfillment_dbg TO deployer, ods_dml;