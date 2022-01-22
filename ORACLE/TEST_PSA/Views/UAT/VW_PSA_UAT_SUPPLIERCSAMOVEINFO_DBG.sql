CREATE OR REPLACE VIEW vw_psa_uat_suppliercsamoveinfo_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.SupplierCsaMoveInfo table
  new_op AS
  (
    SELECT --+ materialize
      scm.*
    FROM vw_psa_plan_sponsor_list            psl 
    JOIN ods.SupplierCsaMoveInfo             scm
      ON scm.psuid = psl.psuid
  ),
  old_op AS
  (
    SELECT --+ materialize
      scm.*
    FROM vw_psa_plan_sponsor_list            psl 
    JOIN ods.SupplierCsaMoveInfo@psa         scm
      ON scm.psuid = psl.psuid
  )
SELECT 'SupplierCsaMoveInfo : NEW'  AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'SupplierCsaMoveInfo : OLD'  AS Compare, o.* FROM (SELECT * FROM old_op) o;

GRANT SELECT ON vw_psa_uat_suppliercsamoveinfo_dbg TO deployer, ods_dml;