CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_bpu_bplv_xref_dbg AS
WITH
  -- 27-Apr-2021, OK: modified.
  -- 23-Apr-2021, OK: created.
  par AS
  (
    SELECT /*+ materialize */ *
    FROM vw_psa_tst_rgr_processes
  )
SELECT --+ ordered use_nl(bbx bpu bplv) index(bbx) index(bpu)
  bbx.bpu_skey, bpu.bpu_cd, bbx.bplv_id,  
  bplv.BenefitInfoCD||'-'||bplv.ProvisionCD||'-'||bplv.LineValueCD              AS bplv_cd,
  bbx.start_dt, 
  bbx.end_dt,
  (
    SELECT
      LISTAGG
      (
        pbx.ProductCD ||
        CASE
          WHEN pbx.ProductCD = 'MAH' THEN '_'||bplv.LineValueCD
          WHEN pbx.ProductCD = 'AHYW' THEN '_'||pbx.FamilyID
        END,
        ';'
      )
      WITHIN GROUP (ORDER BY pbx.ProductCD)                                     AS product_list
    FROM ahmadmin.ProductBPLVXref                               pbx
    WHERE pbx.BenefitProvLineValID = bplv.BenefitProvLineValID
    AND pbx.ActiveFLG = 'Y'
  ) AS product_list,
  bbx.proc_id,
  DECODE(bbx.proc_id, p.test_proc_id, 'TEST', 'REFERENCE')                      AS proc_type,
  pl.start_time,
  cnf.test_case, cnf.test_num,
  pl.comment_txt
FROM par                                                        p 
JOIN tst_rgr_psa_bpu_bplv_xref                                  bbx
  ON bbx.proc_id IN (p.test_proc_id, p.ref_proc_id)     
JOIN tst_rgr_psa_bpu                                            bpu
  ON bpu.proc_id = bbx.proc_id AND bpu.bpu_skey = bbx.bpu_skey      
JOIN ahmadmin.benefitprovisionlinevalue                         bplv
  ON bplv.BenefitProvLineValID = bbx.bplv_id
LEFT JOIN test_psa.cnf_tests                                    cnf
  ON cnf.proc_id = p.ref_proc_id
LEFT JOIN debuger.dbg_process_logs                              pl
 ON pl.proc_id = bbx.proc_id;

GRANT SELECT ON test_psa.vw_psa_tst_rgr_bpu_bplv_xref_dbg TO PUBLIC;
