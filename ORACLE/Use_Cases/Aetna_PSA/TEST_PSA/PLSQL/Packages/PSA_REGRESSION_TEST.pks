CREATE OR REPLACE PACKAGE test_psa.psa_regression_test AS
/*
  Procedures and functions for PSA regresssion testing.
  
  History of changes (newest to oldest):
  ------------------------------------------------------------------------------
  02-May-2021, OK: renamed procedure RUN_ALL to RUN_TESTS and added to it parameter P_TEST_NUM.
  01-May-2021, OK: added parameter P_TODAY to procedures RUN_ONE and RUN_ALL.
  15-Feb-2021, O.Khaykin: added parameter P_NOTE to RUN_ONE.
  13-Feb-2021, Ravi Donakonda, OK: added procedure RUN_ALL, removed function TOTALS. 
*/
  -- Types for all test tables:
  TYPE typ_tab_supp IS TABLE OF tst_rgr_supp%ROWTYPE;
  tab_supp   typ_tab_supp;
  
  TYPE typ_tab_purchased_product IS TABLE OF tst_rgr_purchased_product%ROWTYPE;
  tab_purchased_product   typ_tab_purchased_product;
  
  TYPE typ_tab_plan_sponsor IS TABLE OF tst_rgr_plan_sponsor%ROWTYPE;
  tab_plan_sponsor   typ_tab_plan_sponsor;
  
  TYPE typ_tab_psa_controls IS TABLE OF tst_rgr_psa_controls%ROWTYPE;
  tab_psa_controls    typ_tab_psa_controls;
  
  TYPE typ_tab_psa_bpu IS TABLE OF tst_rgr_psa_bpu%ROWTYPE;
  tab_psa_bpu   typ_tab_psa_bpu;
  
  TYPE typ_tab_psa_bpu_bplv_xref IS TABLE OF tst_rgr_psa_bpu_bplv_xref%ROWTYPE;
  tab_psa_bpu_bplv_xref   typ_tab_psa_bpu_bplv_xref;
  
  TYPE typ_tab_psa_bpu_supplier_xref IS TABLE OF tst_rgr_psa_bpu_supplier_xref%ROWTYPE;
  tab_psa_bpu_supplier_xref typ_tab_psa_bpu_supplier_xref;
  
  TYPE typ_tab_psa_bpu_evolution IS TABLE OF tst_rgr_psa_bpu_evolution%ROWTYPE;
  tab_psa_bpu_evolution   typ_tab_psa_bpu_evolution;
  
  PROCEDURE run_one
  (
    p_batch_skey    IN INTEGER, 
    p_psuid         IN VARCHAR2, 
    p_user          IN VARCHAR2,
    p_commit        IN CHAR DEFAULT NULL,
    p_note          IN VARCHAR2 DEFAULT NULL,
    p_today         IN DATE DEFAULT TRUNC(SYSDATE)
  );
  
  PROCEDURE run_tests
  (
    p_user          IN VARCHAR2,
    p_test_case     IN VARCHAR2 DEFAULT NULL,
    p_test_num      IN PLS_INTEGER DEFAULT NULL,
    p_commit        IN CHAR DEFAULT 'Y',
    p_today         IN DATE DEFAULT TRUNC(SYSDATE)
  );
  
END;
/

GRANT EXECUTE ON test_psa.psa_regression_test TO ahmadmin_dml, ods_dml;