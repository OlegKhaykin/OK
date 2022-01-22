CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_bpu_supp_xref_dbg AS
SELECT
  -- 27-Apr-2021, OK: modified.
  -- 23-Apr-2021, OK: created
  bsx.bpu_skey,
  bpu.bpu_cd,
  bsx.start_dt,   
  bsx.end_dt,
  bsx.supplier_id,      
  rs.SupplierNM,
  bsx.inserted_ts,
  bsx.updated_ts,
  bsx.proc_id,
  DECODE(bsx.proc_id, p.test_proc_id, 'TEST', 'REFERENCE')  AS proc_type,
  pl.start_time,
  c.test_case, c.test_num,
  pl.comment_txt
FROM vw_psa_tst_rgr_processes                           p
JOIN tst_rgr_psa_bpu_supplier_xref                      bsx
  ON bsx.proc_id IN (p.test_proc_id, p.ref_proc_id)
JOIN tst_rgr_psa_bpu                                    bpu
  ON bpu.proc_id = bsx.proc_id
 AND bpu.bpu_skey = bsx.bpu_skey
JOIN tst_rgr_supp                                       rs
  ON rs.proc_id = bsx.proc_id
 AND rs.SupplierID = bsx.supplier_id
LEFT JOIN test_psa.cnf_tests c
  ON c.proc_id = p.ref_proc_id
LEFT JOIN debuger.dbg_process_logs                      pl
  ON pl.proc_id = bsx.proc_id;

GRANT SELECT ON test_psa.vw_psa_tst_rgr_bpu_supp_xref_dbg TO PUBLIC;