CREATE OR REPLACE VIEW vw_psa_uat_sb1_suppliercsamoveinfo AS
WITH
  -- 06-Jan-2021,Sunil Nando: created UAT test view for SupplierCsaMoveInfo table
  new_op AS
  (
    SELECT --+ materialize
      scm.PSUID,
      scm.CtrlSuffixAcnt, 
      scm.PlanSummaryCD,
      scm.OldSupplierID, 
      scm.NewSupplierID,
      TRUNC(scm.CSAEffStartDT) AS CSAEffStartDT, 
      TRUNC(scm.CSAEffEndDT)   AS CSAEffEndDT
    FROM vw_psa_plan_sponsor_list            psl 
    JOIN ods.SupplierCsaMoveInfo             scm
      ON scm.psuid = psl.psuid
  ),
  old_op AS
  (
    SELECT --+ materialize
      scm.PSUID,
      scm.CtrlSuffixAcnt, 
      scm.PlanSummaryCD,
      scm.OldSupplierID, 
      scm.NewSupplierID,
      TRUNC(scm.CSAEffStartDT) AS CSAEffStartDT, 
      TRUNC(scm.CSAEffEndDT)   AS CSAEffEndDT
    FROM vw_psa_plan_sponsor_list            psl 
    JOIN ods.SupplierCsaMoveInfo@sb1         scm
      ON scm.psuid = psl.psuid
  )
SELECT
  'SupplierCsaMoveInfo : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'SupplierCsaMoveInfo : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_sb1_suppliercsamoveinfo TO deployer, ods_dml;