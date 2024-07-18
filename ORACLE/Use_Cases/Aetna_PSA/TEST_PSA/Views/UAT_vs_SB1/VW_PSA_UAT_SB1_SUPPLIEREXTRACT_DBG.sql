CREATE OR REPLACE VIEW vw_psa_uat_sb1_supplierextract_dbg AS
WITH
-- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.SupplierExtract table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid, se.*
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ahmadmin.supplier                            sup
      ON sup.psuid = psl.psuid
    JOIN ods.SupplierExtract                          se
      ON se.ahmsupplierID = sup.ahmsupplierID
  ),
  old_op AS
  (
    SELECT --+ materialize
    DISTINCT psl.psuid, se.*
    FROM vw_psa_plan_sponsor_list                                         psl 
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
    JOIN ods.SupplierExtract@sb1                                          se
      ON se.ahmsupplierID = sup.ahmsupplierID
  )
SELECT 'SupplierExtract : NEW'  AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'SupplierExtract : OLD'  AS Compare, o.* FROM (SELECT * FROM old_op) o;

GRANT SELECT ON vw_psa_uat_sb1_supplierextract_dbg TO deployer, ods_dml;