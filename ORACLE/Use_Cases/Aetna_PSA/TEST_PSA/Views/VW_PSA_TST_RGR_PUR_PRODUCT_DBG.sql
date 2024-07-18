CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_pur_product_dbg AS
SELECT
  -- 28-Apr-2021, OK: modified.
  -- 23-Apr-2021, OK: created.
  rs.psuid,
  pp.SupplierID,
  rs.SupplierNM,
  pp.ProductCD,
  DENSE_RANK() OVER(PARTITION BY pp.proc_id, pp.SupplierID ORDER BY pp.ProductCD) AS prd_num,
  pp.ProductLiveDT, 
  pp.ProductTerminationDT, 
  pp.ContractEndDT,
  pp.AccountID,
  pp.ProductSettingStatusID,
  pp.ProductOwner,
  pp.MinRequiredAge,
  pp.TestSupplierIND,
  pp.AlreadyInProduction,
  pp.TargetPopulationMnemonic,
  pp.proc_id,
  DECODE(pp.proc_id, p.test_proc_id, 'TEST', 'REFERENCE')                         AS proc_type,
  pl.start_time,
  c.test_case, c.test_num, pl.comment_txt
FROM vw_psa_tst_rgr_processes                       p
JOIN tst_rgr_purchased_product                      pp
  ON pp.proc_id IN (p.test_proc_id, p.ref_proc_id)
JOIN tst_rgr_supp                                   rs
  ON rs.SupplierID = pp.SupplierID
 AND rs.proc_id = pp.proc_id
JOIN test_psa.cnf_tests c
  ON c.proc_id = p.ref_proc_id
LEFT JOIN debuger.dbg_process_logs                  pl
 ON pl.proc_id = pp.proc_id;

GRANT SELECT ON test_psa.vw_psa_tst_rgr_pur_product_dbg TO deployer, ods_dml, ahmadmin_read;
