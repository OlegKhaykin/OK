CREATE OR REPLACE VIEW vw_psa_uat_prgm_suppr_process AS
WITH
  -- 06-Jan-2021,Sunil Nando: created UAT test view for ProgramSuppressionProcess table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid,psp.insuranceorgid,psp.programtypecd,psp.settinglevelmnemonicd,
      psp.suppliertermdt,psp.datasourcenm,psp.memberid,psp.memberplanid,
      psp.actiontypemnemoniccd,psp.processflg,psp.processstatus
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ahmadmin.Supplier                            sup
      ON sup.psuid = psl.psuid
    JOIN ods.ProgramSuppressionProcess                psp
      ON psp.AHMSupplierID = sup.AHMSupplierID
  ),
  old_op AS
  (
    SELECT --+ materialize
    DISTINCT
      psl.psuid,psp.insuranceorgid,psp.programtypecd,psp.settinglevelmnemonicd,
      psp.suppliertermdt,psp.datasourcenm,psp.memberid,psp.memberplanid,
      psp.actiontypemnemoniccd,psp.processflg,psp.processstatus
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
    JOIN ods.ProgramSuppressionProcess@psa                                psp
      ON psp.AHMSupplierID = sup.AHMSupplierID
  )
SELECT
  'ProgramSuppressionProcess : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'ProgramSuppressionProcess : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_prgm_suppr_process TO Deployer, ods_dml;