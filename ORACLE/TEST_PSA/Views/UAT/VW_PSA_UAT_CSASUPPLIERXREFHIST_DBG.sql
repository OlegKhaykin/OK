CREATE OR REPLACE VIEW vw_psa_uat_csasupplierxrefhist_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.CSASupplierXrefHist table
  new_op AS
  (
    SELECT --+ materialize
      csxh.*
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ods.CSASupplierXrefHist                      csxh
      ON (csxh.psuid = psl.psuid OR csxh.newpsuid = psl.psuid)
  ),
  old_op AS
  (
    SELECT --+ materialize
      csxh.*
    FROM vw_psa_plan_sponsor_list                      psl 
    JOIN ods.CSASupplierXrefHist@psa                   csxh
      ON (csxh.psuid = psl.psuid OR csxh.newpsuid = psl.psuid)
  )
SELECT 'CSASupplierXrefHist : NEW'  AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'CSASupplierXrefHist : OLD'  AS Compare, o.* FROM (SELECT * FROM old_op) o;

GRANT SELECT ON vw_psa_uat_csasupplierxrefhist_dbg TO deployer, ods_dml;