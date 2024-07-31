CREATE OR REPLACE VIEW test_psa.vw_psa_rgr_differences AS
SELECT
  -- 24-Feb-2021, OK: two colums - TEST_PROC_ID and REF_PROC_ID instead of one.
  -- 11-Feb-2021: Sunil, Ravi, Aanchal, Oleg - created
  compare, test_proc_id, ref_proc_id, COUNT(1) diff_cnt      FROM vw_psa_tst_rgr_plan_sponsor  GROUP BY compare, test_proc_id, ref_proc_id UNION ALL
SELECT compare, test_proc_id, ref_proc_id, COUNT(1) diff_cnt FROM vw_psa_tst_rgr_psa_controls  GROUP BY compare, test_proc_id, ref_proc_id UNION ALL 
SELECT compare, test_proc_id, ref_proc_id, COUNT(1) diff_cnt FROM vw_psa_tst_rgr_psa_bpu       GROUP BY compare, test_proc_id, ref_proc_id UNION ALL
SELECT compare, test_proc_id, ref_proc_id, COUNT(1) diff_cnt FROM vw_psa_tst_rgr_bpu_bplv_xref GROUP BY compare, test_proc_id, ref_proc_id UNION ALL
SELECT compare, test_proc_id, ref_proc_id, COUNT(1) diff_cnt FROM vw_psa_tst_rgr_supp          GROUP BY compare, test_proc_id, ref_proc_id UNION ALL
SELECT compare, test_proc_id, ref_proc_id, COUNT(1) diff_cnt FROM vw_psa_tst_rgr_bpu_supp_xref GROUP BY compare, test_proc_id, ref_proc_id UNION ALL
SELECT compare, test_proc_id, ref_proc_id, COUNT(1) diff_cnt FROM vw_psa_tst_rgr_pur_product   GROUP BY compare, test_proc_id, ref_proc_id;

GRANT SELECT ON vw_psa_rgr_differences TO deployer, ods_dml, ahmadmin_read;
