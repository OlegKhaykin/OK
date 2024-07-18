CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_bpu_supp_xref AS
WITH
  -- 15-Mar-2021, R.Donakonda : Modified , Added case statement for end_dt
  -- ...
  -- 10-Feb-2021, A.Kapoor: created.
  res AS
  (
    SELECT --+ materialize
      t.COLUMN_VALUE                                                                        AS result_type,
      p.test_proc_id,
      p.ref_proc_id,
      bpu.bpu_cd, 
      DECODE(bsx.start_dt, TRUNC(bsx.inserted_ts)+1, DATE '0001-01-01', bsx.start_dt)       AS start_dt,   
      CASE 
        WHEN bsx.end_dt IN (TRUNC(bsx.updated_ts), TRUNC(bsx.Updated_TS)+1)
          THEN DATE '0001-01-01'
        ELSE bsx.end_dt
      END                                                                                   AS end_dt,      
      rs.SupplierNM
    FROM vw_psa_tst_rgr_processes                                               p
    CROSS JOIN TABLE(tab_number(1, 2))                                          t
    JOIN tst_rgr_psa_bpu_supplier_xref                                          bsx
      ON bsx.proc_id = DECODE(t.COLUMN_VALUE, 1, p.test_proc_id, p.ref_proc_id)
    JOIN tst_rgr_psa_bpu                                                        bpu
      ON bpu.proc_id = bsx.proc_id
     AND bpu.bpu_skey = bsx.bpu_skey
    JOIN tst_rgr_supp                                                           rs
      ON rs.proc_id = bsx.proc_id
     AND rs.SupplierID = bsx.supplier_id
    LEFT JOIN tst_rgr_supp                                rs
      ON rs.SupplierID = bsx.supplier_id
     AND rs.proc_id = bsx.proc_id
  )
  , test_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, bpu_cd, start_dt, end_dt, SupplierNM
    FROM res
    WHERE result_type = 1
  )
  , ref_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, bpu_cd, start_dt, end_dt, SupplierNM
    FROM res
    WHERE result_type = 2
  )
SELECT 'VW_PSA_TST_RGR_BPU_SUPP_XREF: Test MINUS Ref.' compare, d.* FROM (SELECT * FROM test_data MINUS SELECT * FROM ref_data) d
UNION ALL
SELECT 'VW_PSA_TST_RGR_BPU_SUPP_XREF: Ref. MINUS Test' compare, d.* FROM (SELECT * FROM ref_data MINUS SELECT * FROM test_data) d; 

GRANT SELECT ON vw_psa_tst_rgr_bpu_supp_xref TO deployer, ods_dml, ahmadmin_read;