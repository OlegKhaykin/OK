CREATE OR REPLACE VIEW vw_psa_uat_assignedtask_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for AssignedTask table
  new_op AS
  (
    SELECT --+ materialize
    DISTINCT  psl.psuid, ast.*
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
    DISTINCT  psl.psuid, ast.*
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
SELECT 'AssignedTask : NEW'  AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'AssignedTask : OLD'  AS Compare, o.* FROM (SELECT * FROM old_op) o;

GRANT SELECT ON vw_psa_uat_assignedtask_dbg TO deployer, ods_dml;