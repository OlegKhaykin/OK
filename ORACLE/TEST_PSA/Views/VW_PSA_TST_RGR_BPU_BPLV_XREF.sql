CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_bpu_bplv_xref AS
WITH
  -- 15-Mar-2021, R.Donakonda : Modified, Added case statement for end_dt
  -- ...
  -- 10-Feb-2021, A.Kapoor: created.
  res AS
  (
    SELECT --+ materialize
      t.COLUMN_VALUE                                                               AS result_type,
      p.test_proc_id,
      p.ref_proc_id,
      bpu.bpu_cd,
      bplv.BenefitInfoCD||'-'||bplv.ProvisionCD||'-'||bplv.LineValueCD             AS bplv_cd,
      bbx.start_dt, 
      CASE 
       WHEN bbx.end_dt = TRUNC(bbx.Updated_TS) OR bbx.end_dt - 1 = TRUNC(bbx.Updated_TS)
        THEN DATE '2001-01-01'
       ELSE bbx.end_dt
      END                                                                           AS end_dt,      
      LISTAGG
      (
        pbx.ProductCD ||
        CASE
          WHEN pbx.ProductCD = 'MAH' THEN '_'||bplv.LineValueCD
          WHEN pbx.ProductCD = 'AHYW' THEN '_'||pbx.FamilyID
        END,
        ';'
      ) WITHIN GROUP (ORDER BY pbx.ProductCD)                                      AS product_list
    FROM vw_psa_tst_rgr_processes                               p  
    CROSS JOIN TABLE(tab_number(1, 2))                          t 
    JOIN tst_rgr_psa_bpu_bplv_xref                              bbx
      ON bbx.proc_id = DECODE(t.COLUMN_VALUE, 1, p.test_proc_id, p.ref_proc_id)     
    JOIN tst_rgr_psa_bpu                                        bpu
      ON bpu.proc_id = bbx.proc_id
     AND bpu.bpu_skey = bbx.bpu_skey      
    JOIN ahmadmin.benefitprovisionlinevalue                     bplv
      ON bplv.BenefitProvLineValID = bbx.bplv_id
    JOIN ahmadmin.ProductBPLVXref                               pbx
      ON pbx.BenefitProvLineValID = bplv.BenefitProvLineValID
     AND pbx.ActiveFLG = 'Y'
    GROUP BY
     t.COLUMN_VALUE, bbx.proc_id, p.test_proc_id, p.ref_proc_id,
     bpu.bpu_cd, bplv.BenefitInfoCD, bplv.ProvisionCD, bplv.LineValueCD,
     bbx.start_dt, bbx.end_dt, bbx.Updated_TS
  )
--select * from res
  , test_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, bpu_cd, bplv_cd, start_dt, end_dt, product_list
    FROM res WHERE result_type = 1
  )
  , ref_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, bpu_cd, bplv_cd, start_dt, end_dt, product_list
    FROM res WHERE result_type = 2
  )
--select * from ref_data
SELECT 'VW_PSA_TST_RGR_BPU_BPLV_XREF: Test MINUS Ref.' AS compare, d.* FROM (SELECT * FROM test_data MINUS SELECT * FROM ref_data) d
UNION ALL
SELECT 'VW_PSA_TST_RGR_BPU_BPLV_XREF: Ref. MINUS Test' AS compare, d.* FROM (SELECT * FROM ref_data MINUS SELECT * FROM test_data) d;

GRANT SELECT ON vw_psa_tst_rgr_bpu_bplv_xref TO deployer, ods_dml, ahmadmin_read;
