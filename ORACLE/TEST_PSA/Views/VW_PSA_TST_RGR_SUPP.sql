CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_supp AS
WITH
  -- 15-Mar-2021, R.Donakonda : Modified , Added case statement for effectiveenddt
  -- 07-Mar-2021, R.Donakonda : Modified ,added static value for effectivestartdt,effectiveenddt,active_since_dt if it equals to SYSDATE.
  -- 15-Feb-2021, OK: added columns PSUID, PRODUCT_LIST and ACTIVE_SINCE_DT.
  -- 12-Feb-2021, R.Donakonda: modified.
  -- 10-Feb-2021, R.Donakonda: created.
  res AS
  (
    SELECT --+ materialize
      t.COLUMN_VALUE                                                                                     AS result_type,
      p.test_proc_id,
      p.ref_proc_id,
      s.psuid,
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
      DECODE(s.effectivestartdt, TRUNC(s.RecordupdtDT), DATE '2001-01-01', s.effectivestartdt)           AS effectivestartdt, 
      CASE 
       WHEN s.effectiveenddt = TRUNC(s.RecordupdtDT) OR s.effectiveenddt - 1 = TRUNC(s.RecordupdtDT)
        THEN DATE '2001-01-01'
       ELSE s.effectiveenddt
      END                                                                                                AS effectiveenddt,         
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
      DECODE(s.active_since_dt - 1 , TRUNC(s.RecordupdtDT), DATE '2001-01-01', s.active_since_dt)        AS active_since_dt
    FROM vw_psa_tst_rgr_processes       p 
    CROSS JOIN TABLE(tab_number(1, 2))  t    
    JOIN tst_rgr_supp                   s
      ON s.proc_id = DECODE(t.COLUMN_VALUE, 1, p.test_proc_id, p.ref_proc_id)
  ), 
  test_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, psuid, SupplierNM, hdmsclientreferenceid, ceservernm, mastertypecd,
      portalflg, claimsflg, healthplanriskid, populationtypeid, productionstatusid,hdmslastfeeddt,
      dmfirstfeeddt, hdmsdeliverybeforedaynm, hdmsdeliverybeforedaynum, hdmsdatafrequencyid,
      hdmsdeliveryafterdaynm, hdmsdeliveryafterdaynum, projectedmembertransferdt, membertransferrequiredflg,
      membertransferreasonid, hdmsfirstfeeddt, dmfirstactivitydt, effectivestartdt, effectiveenddt,
      suppliertypeid, providerassigmnemonic, providerassigfreqmnemonic, defaultbusinesssupplierflg,
      usagemnemonic, pcpdatasourcenm, relatedahmbusinesssupplierid, attributedflag, aetnainternationalflg,
      emailconsentflg, datashareconsentflg, datasourcenm, product_list, active_since_dt
    FROM res
    WHERE result_type = 1
  ),
  ref_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id, psuid, SupplierNM, hdmsclientreferenceid, ceservernm, mastertypecd,
      portalflg, claimsflg, healthplanriskid, populationtypeid, productionstatusid,hdmslastfeeddt,
      dmfirstfeeddt, hdmsdeliverybeforedaynm, hdmsdeliverybeforedaynum, hdmsdatafrequencyid,
      hdmsdeliveryafterdaynm, hdmsdeliveryafterdaynum, projectedmembertransferdt, membertransferrequiredflg,
      membertransferreasonid, hdmsfirstfeeddt, dmfirstactivitydt, effectivestartdt, effectiveenddt,
      suppliertypeid, providerassigmnemonic, providerassigfreqmnemonic, defaultbusinesssupplierflg,
      usagemnemonic, pcpdatasourcenm, relatedahmbusinesssupplierid, attributedflag, aetnainternationalflg,
      emailconsentflg, datashareconsentflg, datasourcenm, product_list, active_since_dt
    FROM res
    WHERE result_type = 2
  )  
SELECT 'VW_PSA_TST_RGR_SUPP: Test MINUS Ref.' compare, d.* FROM (SELECT * FROM test_data MINUS SELECT * FROM ref_data) d
UNION ALL
SELECT 'VW_PSA_TST_RGR_SUPP: Ref. MINUS Test' compare, d.* FROM (SELECT * FROM ref_data MINUS SELECT * FROM test_data) d; 

GRANT SELECT ON vw_psa_tst_rgr_supp TO deployer, ods_dml, ahmadmin_read;
