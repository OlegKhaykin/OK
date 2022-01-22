create or replace view vw_psa_uat_csasupplierxref_dbg as
WITH
  -- 02-Mar-2021,R.Donakonda: created UAT test dbg view for ods.csasupplierxref table
  new_op AS
  (
    SELECT --+ materialize
      csx.*
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ods.csasupplierxref                          csx
      ON csx.psuid = psl.psuid
  ),
  old_op AS
  (
    SELECT --+ materialize
      csx.*
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ods.csasupplierxref@psa                      csx
      ON csx.psuid = psl.psuid
  )
SELECT 'ODS.CSASupplierxref : NEW' AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'ODS.CSASupplierxref : OLD' AS Compare, o.* FROM (SELECT * FROM old_op) o;

GRANT SELECT ON vw_psa_uat_csasupplierxref_dbg TO deployer, ods_dml;