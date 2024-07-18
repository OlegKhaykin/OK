create or replace view vw_psa_uat_sb1_csasupplier_xr_dbg as
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for vw_csasupplierxref table
  new_results AS
  (
    SELECT --+ materialize
      csa.*
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.vw_csasupplierxref_new                                   csa
      ON csa.PlanSponsorUniqueId = ppsl.psuid   
  ),
  old_results AS
  (
    SELECT --+ materialize
      csa.*
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.vw_csasupplierxref_old@sb1                               csa
      ON csa.PlanSponsorUniqueId = ppsl.psuid    
  )
SELECT 'vw_csasupplierxref : NEW' AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'vw_csasupplierxref : OLD' AS Compare, o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_sb1_csasupplier_xr_dbg TO deployer, ods_dml;
