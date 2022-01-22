CREATE OR REPLACE VIEW vw_psa_uat_sb1_ceodsrunsync AS
WITH
  -- 25-Feb-2021,Sunil Nando: created UAT test view for CEODSRunSync table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid,
      cor.CELockFlag, 
      cor.ODSLockFlag
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
    DISTINCT
      psl.psuid,
      cor.CELockFlag, 
      cor.ODSLockFlag
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
    JOIN ahmadmin.SupplierGroup@sb1                                       sg
      ON sg.SupplierID = sup.SupplierID 
     AND sg.SupplierGroupTypeID = 1 
    JOIN ahmadmin.MasterSupplier@sb1                                      ms
      ON ms.MasterSupplierID = sg.SupplierGroupID    
    JOIN ods.CEODSRunSync@sb1                                             cor
      ON cor.mastersupplierid = ms.AHMSupplierID
  )
SELECT
  'CEODSRunSync : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'CEODSRunSync : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_sb1_ceodsrunsync TO deployer, ods_dml;