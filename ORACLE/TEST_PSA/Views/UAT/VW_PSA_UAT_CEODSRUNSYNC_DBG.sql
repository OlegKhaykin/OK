CREATE OR REPLACE VIEW vw_psa_uat_ceodsrunsync_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.CEODSRunSync table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid, cor.*
    FROM vw_psa_plan_sponsor_list                              psl
    JOIN ahmadmin.Supplier                                     sup
      ON sup.psuid = psl.psuid
    JOIN ahmadmin.SupplierGroup                                sg
      ON sg.SupplierID = sup.SupplierID
     AND sg.SupplierGroupTypeID = 1
    JOIN ahmadmin.MasterSupplier                               ms
      ON ms.MasterSupplierID = sg.SupplierGroupID
    JOIN ods.CEODSRunSync                                      cor
      ON cor.mastersupplierid = ms.AHMSupplierID
  ),
  old_op AS
  (
    SELECT --+ materialize
    DISTINCT psl.psuid, cor.*
    FROM vw_psa_plan_sponsor_list                                         psl
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
    JOIN ahmadmin.SupplierGroup@psa                                       sg
      ON sg.SupplierID = sup.SupplierID
     AND sg.SupplierGroupTypeID = 1
    JOIN ahmadmin.MasterSupplier@psa                                      ms
      ON ms.MasterSupplierID = sg.SupplierGroupID
    JOIN ods.CEODSRunSync@psa                                             cor
      ON cor.mastersupplierid = ms.AHMSupplierID
  )
SELECT 'CEODSRunSync : NEW'  AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'CEODSRunSync : OLD'  AS Compare, o.* FROM (SELECT * FROM old_op) o;


GRANT SELECT ON vw_psa_uat_ceodsrunsync_dbg TO deployer, ods_dml;