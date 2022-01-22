CREATE OR REPLACE VIEW vw_psa_uat_sb1_assignedadminuser_dbg AS
WITH
  -- 01-Mar-2021,R.Donakonda: created UAT test dbg view for AssignedAdminUser table
  new_op AS
  (
    SELECT --+ materialize
    DISTINCT psl.psuid,aau.*
    FROM vw_psa_plan_sponsor_list                                         psl
    JOIN ahmadmin.Supplier                                                sup
      ON sup.psuid = psl.psuid                                            
    JOIN ahmadmin.WorkFlowProcessInstance                                 wfpi
      ON wfpi.referencedobjectid = sup.SupplierID                         
    JOIN ahmadmin.AssignedTask                                            ast
      ON ast.workflowprocessinstanceid = wfpi.workflowprocessinstanceid
    JOIN ahmadmin.AssignedAdminUser                                       aau
      ON aau.assignedtaskid = ast.assignedtaskid
  ),
  old_op AS
  (
    SELECT --+ materialize
    DISTINCT psl.psuid,aau.*
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
      ON wfpi.referencedobjectid = sup.SupplierID      
    JOIN ahmadmin.AssignedTask@sb1                                        ast
      ON ast.workflowprocessinstanceid = wfpi.workflowprocessinstanceid
    JOIN ahmadmin.AssignedAdminUser@sb1                                   aau
      ON aau.assignedtaskid = ast.assignedtaskid
  )
SELECT 'AssignedAdminUser : NEW'  AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'AssignedAdminUser : OLD'  AS Compare, o.* FROM (SELECT * FROM old_op) o;

GRANT SELECT ON vw_psa_uat_sb1_assignedadminuser_dbg TO deployer, ods_dml;