CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_source_data AS
WITH
  -- 27-Apr-2021, OK: created
  prc AS
  (
    SELECT --+ materialize
      pl.proc_id,
      DECODE(pl.proc_id, p.test_proc_id, 'TEST', 'REFERENCE')                         AS proc_type,
      TO_NUMBER(REGEXP_SUBSTR(pl.comment_txt, 'P_BATCH_SKEY=([^,]*)', 1, 1, 'i', 1))  AS batch_skey,
      TO_NUMBER(REGEXP_SUBSTR(pl.comment_txt, 'P_PSUID=([^,]*)', 1, 1, 'i', 1))       AS psuid,
      pl.comment_txt, cnf.test_case, cnf.test_num
    FROM test_psa.vw_psa_tst_rgr_processes                        p
    JOIN debuger.dbg_process_logs                                 pl
      ON pl.proc_id IN (p.test_proc_id, p.ref_proc_id)
    LEFT JOIN test_psa.cnf_tests                                  cnf
      ON cnf.proc_id = p.ref_proc_id
  )
SELECT --+ ordered use_nl(c x)
  c.psuid||'-'||c.ControlGroupNM||'-'||x.SuffixNM||'-'||x.AccountNM||'-'||x.PlanSummaryCD AS bpu_cd,
  x.BenefitInfoCD||'-'||x.ProvisionCD||'-'||x.LineValueCD                                 AS bplv_cd,
  LISTAGG(x.ProductCD, ';') WITHIN GROUP(ORDER BY x.ProductCD)                            AS product_list,
  TRUNC(MIN(x.SupplierEffectiveStartDT))                                                  AS start_dt,
  TRUNC(MAX(x.SupplierEffectiveEndDT))                                                    AS end_dt,
  q.proc_id, q.proc_type, q.test_case, q.test_num, q.comment_txt
FROM prc                                                          q
JOIN ods.STG_SupplierControl                                      c
  ON c.SUPPLIERBATCHSKEY = q.batch_skey
 AND c.psuid = q.psuid
JOIN ods.STG_SupplierControlBPLVXRef                              x
  ON x.STGSupplierControlSKEY = c.STGSupplierControlSKEY
GROUP BY c.psuid, c.ControlGroupNM, SuffixNM, x.AccountNM, x.PlanSummaryCD,
 x.BenefitInfoCD, x.ProvisionCD, x.LineValueCD, 
 q.proc_id, q.proc_type, q.comment_txt, q.test_case, q.test_num, q.comment_txt;

GRANT SELECT ON test_psa.vw_psa_tst_rgr_source_data TO public;