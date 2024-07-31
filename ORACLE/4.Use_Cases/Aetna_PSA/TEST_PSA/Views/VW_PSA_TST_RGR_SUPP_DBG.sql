CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_supp_dbg AS
SELECT --+ materialize
  -- 27-Apr-2021, OK: created
  s.psuid,
  s.SupplierID,
  s.SupplierNM,
  s.hdmsclientreferenceid,
  s.ceservernm,
  s.mastertypecd,
  s.portalflg,
  s.claimsflg,
  s.healthplanriskid,
  s.populationtypeid,
  s.productionstatusid,
  s.hdmslastfeeddt,
  s.dmfirstfeeddt,
  s.hdmsdeliverybeforedaynm,
  s.hdmsdeliverybeforedaynum,
  s.hdmsdatafrequencyid,
  s.hdmsdeliveryafterdaynm,
  s.hdmsdeliveryafterdaynum,
  s.projectedmembertransferdt,
  s.membertransferrequiredflg,
  s.membertransferreasonid,
  s.hdmsfirstfeeddt,
  s.dmfirstactivitydt,
  s.effectivestartdt, 
  s.effectiveenddt,         
  s.suppliertypeid,
  s.providerassigmnemonic,
  s.providerassigfreqmnemonic,
  s.defaultbusinesssupplierflg,
  s.usagemnemonic,
  s.pcpdatasourcenm,
  s.relatedahmbusinesssupplierid,
  s.attributedflag,
  s.aetnainternationalflg,
  s.emailconsentflg,
  s.datashareconsentflg,
  s.datasourcenm,
  s.product_list,
  s.active_since_dt,
  s.RecordInsertDT                                        AS inserted_ts,
  s.proc_id,
  DECODE(s.proc_id, p.test_proc_id, 'TEST', 'REFERENCE')  AS proc_type,
  pl.start_time,   
  cnf.test_case, cnf.test_num, pl.comment_txt
FROM vw_psa_tst_rgr_processes                       p 
JOIN tst_rgr_supp                                   s
  ON s.proc_id IN (p.test_proc_id, p.ref_proc_id)
LEFT JOIN test_psa.cnf_tests                        cnf
  ON cnf.proc_id = p.ref_proc_id
LEFT JOIN debuger.dbg_process_logs                  pl
  ON pl.proc_id = s.proc_id;
  
GRANT SELECT ON test_psa.vw_psa_tst_rgr_supp_dbg TO public;
