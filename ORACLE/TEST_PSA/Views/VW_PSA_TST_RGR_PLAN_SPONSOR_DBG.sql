CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_plan_sponsor_dbg AS
SELECT
  ps.*,
  DECODE(ps.proc_id, p.test_proc_id, 'TEST', 'REFERENCE') AS proc_type,
  pl.start_time, cnf.test_case, cnf.test_num, pl.comment_txt
FROM vw_psa_tst_rgr_processes                           p 
JOIN tst_rgr_plan_sponsor                               ps
  ON ps.proc_id IN (p.test_proc_id, p.ref_proc_id) 
LEFT JOIN test_psa.cnf_tests                            cnf
  ON cnf.proc_id = p.ref_proc_id
LEFT JOIN debuger.dbg_process_logs                      pl
  ON pl.proc_id = ps.proc_id;

GRANT SELECT ON vw_psa_tst_rgr_plan_sponsor_dbg TO PUBLIC;
