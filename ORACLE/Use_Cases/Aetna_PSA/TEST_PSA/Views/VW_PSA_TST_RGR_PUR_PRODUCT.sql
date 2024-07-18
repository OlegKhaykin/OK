CREATE OR REPLACE VIEW test_psa.vw_psa_tst_rgr_pur_product AS
WITH
  -- 26-Apr-2021, OK: excluded ProductSettingStatusID.
  -- 03-Mar-2021, OK: static value for ProductTerminationDT if it equals to SYSDATE.
  -- 24-Feb-2021, OK: two colums - TEST_PROC_ID and REF_PROC_ID instead of one.
  -- 21-Feb-2021, OK: added column PSUID.
  -- 15-Feb-2021, OK: simplified, added column SupplierNM.
  -- 12-Feb-2021, R.Donakonda: modified.
  -- 10-Feb-2021, A.Kapoor: created.
  res AS
  (
    SELECT --+ materialize
      t.COLUMN_VALUE                                                                                      AS result_type,
      p.test_proc_id,
      p.ref_proc_id,
      rs.psuid,
      rs.SupplierNM,
      pp.ProductCD, 
      pp.ProductLiveDT                                                                                    AS ProductLiveDT, 
      DECODE(pp.ProductTerminationDT, TRUNC(pp.RecordUpdtDT), DATE '2001-01-01', pp.ProductTerminationDT) AS ProductTerminationDT, 
      TRUNC(pp.ContractEndDT)                                                                             AS ContractEndDT,
      pp.AccountID,
      --pp.ProductSettingStatusID,
      pp.ProductOwner,
      pp.MinRequiredAge,
      pp.TestSupplierIND,
      pp.AlreadyInProduction,
      pp.TargetPopulationMnemonic
    FROM vw_psa_tst_rgr_processes                                               p
    CROSS JOIN TABLE(tab_number(1, 2))                                          t 
    JOIN tst_rgr_purchased_product                                              pp
      ON pp.proc_id = DECODE(t.COLUMN_VALUE, 1, p.test_proc_id, p.ref_proc_id)
    JOIN tst_rgr_supp                                                           rs
      ON rs.SupplierID = pp.SupplierID
     AND rs.proc_id = pp.proc_id
  )
  , test_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id,
      psuid, SupplierNM, ProductCD, ProductLiveDT, ProductTerminationDT, ContractEndDT,
      AccountID, --ProductSettingStatusID,
      ProductOwner, MinRequiredAge, TestSupplierIND, AlreadyInProduction, TargetPopulationMnemonic
    FROM res
    WHERE result_type = 1
  )
  , ref_data AS
  (
    SELECT --+ materialize
      test_proc_id, ref_proc_id,
      psuid, SupplierNM, ProductCD, ProductLiveDT, ProductTerminationDT, ContractEndDT,
      AccountID, --ProductSettingStatusID,
      ProductOwner, MinRequiredAge, TestSupplierIND, AlreadyInProduction, TargetPopulationMnemonic
    FROM res
    WHERE result_type = 2
  )
SELECT 'VW_PSA_TST_RGR_PUR_PRODUCT: Test MINUS Ref.' compare, d.* FROM (SELECT * FROM test_data MINUS SELECT * FROM ref_data) d
UNION ALL
SELECT 'VW_PSA_TST_RGR_PUR_PRODUCT: Ref. MINUS Test' compare, d.* FROM (SELECT * FROM ref_data MINUS SELECT * FROM test_data) d; 

GRANT SELECT ON vw_psa_tst_rgr_pur_product TO deployer, ods_dml, ahmadmin_read;
