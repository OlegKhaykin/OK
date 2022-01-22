CREATE OR REPLACE VIEW vw_psa_uat_csasupplier_xr_dbg AS
WITH
  -- 04-Mar-2021, R.Donakonda: created UAT test dbg view for vw_csasupplierxref table
  new_results AS
  (
    SELECT --+ materialize
      csa.*
    FROM vw_psa_plan_sponsor_list                   ppsl 
    JOIN ahmadmin.vw_csasupplierxref_new            csa
      ON csa.PlanSponsorUniqueId = ppsl.psuid   
  ),
  old_results AS
  (
    SELECT --+ materialize
      csa.*
    FROM vw_psa_plan_sponsor_list                   ppsl 
    JOIN ahmadmin.vw_csasupplierxref@psa            csa
      ON csa.PlanSponsorUniqueId = ppsl.psuid    
  )
SELECT 'VW_CSASUPPLIERXREF: NEW' AS Compare, n.* FROM new_results n
UNION ALL
SELECT 'VW_CSASUPPLIERXREF: OLD' AS Compare, o.* FROM old_results o;

GRANT SELECT ON vw_psa_uat_csasupplier_xr_dbg TO deployer, ods_dml;
