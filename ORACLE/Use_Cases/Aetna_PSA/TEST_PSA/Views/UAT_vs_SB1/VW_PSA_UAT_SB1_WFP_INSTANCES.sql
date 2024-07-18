CREATE OR REPLACE VIEW vw_psa_uat_sb1_wfp_instances AS
WITH
  -- 19-Jan-2021,Sunil Nando: created UAT test view for WorkFlowProcessInstance table
  new_op AS
  (
    SELECT --+ materialize
      DISTINCT
      psl.psuid,wfpi.workflowprocessid,wfpi.versionnum,wfpi.qirevisiontypeid, 
      trunc(wfpi.effectivestartdt) AS effectivestartdt,wfpi.changetitletext,wfpi.changedesc 
    FROM vw_psa_plan_sponsor_list                              psl
    JOIN ahmadmin.Supplier                                     sup
      ON sup.psuid = psl.psuid 
    JOIN ahmadmin.WorkFlowProcessInstance                      wfpi
      ON wfpi.ReferencedObjectID = sup.SupplierID
  ),
  old_op AS
  (
    SELECT --+ materialize
      DISTINCT
      psl.psuid,wfpi.workflowprocessid,wfpi.versionnum,wfpi.qirevisiontypeid, 
      trunc(wfpi.effectivestartdt) AS effectivestartdt,wfpi.changetitletext,wfpi.changedesc 
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
    JOIN ahmadmin.WorkFlowProcessInstance@sb1                             wfpi         
      ON wfpi.ReferencedObjectID = sup.SupplierID
  )
SELECT
  'WorkFlowProcessInstance : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'WorkFlowProcessInstance : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_sb1_wfp_instances TO deployer, ods_dml;