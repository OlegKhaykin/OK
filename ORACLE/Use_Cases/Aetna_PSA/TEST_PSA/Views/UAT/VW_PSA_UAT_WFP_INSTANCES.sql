CREATE OR REPLACE VIEW vw_psa_uat_wfp_instances AS
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
    JOIN ahmadmin.WorkFlowProcessInstance@psa                             wfpi         
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

GRANT SELECT ON vw_psa_uat_wfp_instances TO deployer, ods_dml;