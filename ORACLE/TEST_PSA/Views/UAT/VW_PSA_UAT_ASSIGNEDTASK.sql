CREATE OR REPLACE VIEW vw_psa_uat_assignedtask AS
WITH
  -- 19-Jan-2021,Sunil Nando: created UAT test view for AssignedTask table
  new_op AS
  (
    SELECT --+ materialize
    DISTINCT
      psl.psuid,
      taskid, 
      TRUNC(ast.duedt)           AS duedt, 
      TRUNC(ast.completiondt)    AS completiondt, 
      ast.commentstext 
    FROM vw_psa_plan_sponsor_list                                         psl
    JOIN ahmadmin.Supplier                                                sup
      ON sup.psuid = psl.psuid                                            
    JOIN ahmadmin.WorkFlowProcessInstance                                 wfpi
      ON wfpi.ReferencedObjectID = sup.SupplierID                         
    JOIN ahmadmin.AssignedTask                                            ast
      ON ast.workflowprocessinstanceid = wfpi.workflowprocessinstanceid
  ),
  old_op AS
  (
    SELECT --+ materialize
    DISTINCT
      psl.psuid,
      taskid, 
      TRUNC(ast.duedt)           AS duedt, 
      TRUNC(ast.completiondt)    AS completiondt, 
      ast.commentstext 
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
    JOIN ahmadmin.AssignedTask@psa                                        ast
      ON ast.workflowprocessinstanceid = wfpi.workflowprocessinstanceid
  )
SELECT
  'AssignedTask : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'AssignedTask : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_assignedtask TO deployer, ods_dml;