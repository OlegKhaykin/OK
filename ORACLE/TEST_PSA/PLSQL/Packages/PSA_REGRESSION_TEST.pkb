CREATE OR REPLACE PACKAGE BODY test_psa.psa_regression_test AS
/*
  02-May-2021, OK: renamed procedure RUN_ALL to RUN_TESTS and added to it parameter P_TEST_NUM.
  01-May-2021, OK: added parameter P_TODAY to procedures RUN_ONE and RUN_ALL.
  21-Feb-2021, O.Khaykin: allowed list of Test Cases in P_TEST_CASE.
  16-Feb-2021, O.Khaykin: replaced procedure CAPTURE_CHANGES and SAVE_CHANGES with CAPTURE_RESULTS and SAVE_RESULTS respectively.
  15-Feb-2021, O.Khaykin: added parameter P_NOTE to RUN_ONE and used it in RUN_ALL.
  13-Feb-2021, Oleg Khaykn: simplified.
  10-Feb-2021, Ravi Donakonda: added procedure RUN_ALL.
*/
  TYPE typ_info_rec IS RECORD
  (
    table_owner           VARCHAR2(30),
    table_name            VARCHAR2(50),
    rgr_table_name        VARCHAR2(50),
    where_condition       VARCHAR2(200)
  );
  
  TYPE typ_info_tab IS TABLE OF typ_info_rec;

  tab_info    typ_info_tab;

  PROCEDURE init IS
  BEGIN
    SELECT q.* BULK COLLECT INTO tab_info
    FROM
    (
      SELECT
        'AHMADMIN'                      AS table_owner,
        'PLANSPONSOR'                   AS table_name,
        'TST_RGR_PLAN_SPONSOR'          AS rgr_table_name,
        'PlanSponsorUniqueID = :psuid'  AS where_condition
      FROM dual UNION ALL
      SELECT 'AHMADMIN', 'PSA_CONTROLS', 'TST_RGR_PSA_CONTROLS', 'psuid = :psuid' FROM dual UNION ALL
      SELECT 'AHMADMIN', 'PSA_BENEFIT_PROVISION_UNITS', 'TST_RGR_PSA_BPU', 'psuid = :psuid' FROM dual UNION ALL
      SELECT 'AHMADMIN', 'SUPPLIER', 'TST_RGR_SUPP', 'psuid = :psuid' FROM dual UNION ALL
      SELECT 'AHMADMIN', 'PURCHASEDPRODUCT', 'TST_RGR_PURCHASED_PRODUCT',
             'SupplierID IN (SELECT SupplierID FROM ahmadmin.supplier WHERE psuid = :psuid)' FROM dual UNION ALL
      SELECT 'AHMADMIN', 'PSA_BPU_BPLV_XREF', 'TST_RGR_PSA_BPU_BPLV_XREF',
             'bpu_skey IN (SELECT bpu_skey FROM ahmadmin.psa_benefit_provision_units WHERE psuid = :psuid)' FROM dual UNION ALL
      SELECT 'AHMADMIN', 'PSA_BPU_SUPPLIER_XREF', 'TST_RGR_PSA_BPU_SUPPLIER_XREF',
             'bpu_skey IN (SELECT bpu_skey FROM ahmadmin.psa_benefit_provision_units WHERE psuid = :psuid)' FROM dual UNION ALL
      SELECT 'AHMADMIN', 'VW_PSA_BPU_PRODUCT_LISTS', 'TST_RGR_PSA_BPU_EVOLUTION', ':psuid IS NOT NULL' FROM dual
    ) q;
  END;
  
  PROCEDURE capture_results AS
    n_proc_id   INTEGER;
    v_psuid     ahmadmin.psa_controls.psuid%TYPE;
    v_tab       VARCHAR2(60);
    v_coll      VARCHAR2(60);
    v_qry       VARCHAR2(1000);
    n_cnt       PLS_INTEGER;
  BEGIN
    v_psuid := psa.get_parameter('PSUID');
    xl.begin_action('CAPTURE_RESULTS', 'PSUID='||v_psuid, 4, $$PLSQL_UNIT);
    
    n_proc_id := xl.get_current_proc_id;
    
    FOR i IN 1..tab_info.COUNT LOOP
      v_tab  := tab_info(i).table_owner||'.'||tab_info(i).table_name;
      v_coll := 'psa_regression_test.tab_'||SUBSTR(tab_info(i).rgr_table_name, 9);
      
      v_qry :=
     'BEGIN
        SELECT '||n_proc_id||' proc_id, t.*
        BULK COLLECT INTO '||v_coll||'
        FROM '||v_tab||' t WHERE '||tab_info(i).where_condition||';
        
        :n_cnt := '||v_coll||'.COUNT;
      END;';
      
      xl.begin_action(v_tab||' -> '||v_coll, v_qry, 4, $$PLSQL_UNIT);
      EXECUTE IMMEDIATE v_qry USING v_psuid, OUT n_cnt;
      xl.end_action(n_cnt||' rows captured');
    END LOOP;
    
    xl.end_action('CAPTURE_RESULTS: done');
  END;
  
  
  PROCEDURE save_results IS
    v_rgr_tab   VARCHAR2(50);
    v_coll      VARCHAR2(50);
    v_cmd       VARCHAR2(500);
    n_cnt       PLS_INTEGER;
  BEGIN
    xl.begin_action('SAVE_RESULTS', 'Started', 4, $$PLSQL_UNIT);
    
    FOR i IN 1..tab_info.COUNT LOOP
      v_rgr_tab := tab_info(i).rgr_table_name;
      v_coll := 'psa_regression_test.tab_'||SUBSTR(v_rgr_tab, 9);
      
      v_cmd :=
     'BEGIN
        FORALL i IN 1 .. '||v_coll||'.COUNT
        INSERT INTO '||v_rgr_tab||'
        VALUES '||v_coll||'(i);
          
        :n_cnt := NVL(SQL%ROWCOUNT, 0);
      END;';
        
      xl.begin_action(v_coll||' -> '||v_rgr_tab, v_cmd, 4, $$PLSQL_UNIT);
      EXECUTE IMMEDIATE v_cmd USING OUT n_cnt;
      xl.end_action(n_cnt||' rows saved');
    END LOOP;
    
    xl.end_action('SAVE_RESULTS: done');
  END;
  
  
  PROCEDURE run_one
  (
    p_batch_skey    IN INTEGER, 
    p_psuid         IN VARCHAR2, 
    p_user          IN VARCHAR2,
    p_commit        IN CHAR DEFAULT NULL,
    p_note          IN VARCHAR2 DEFAULT NULL,
    p_today         IN DATE DEFAULT TRUNC(SYSDATE)
  ) IS
    dt_start        DATE;
    rc_res          SYS_REFCURSOR;
  BEGIN
    xl.open_log
    (
      'RUN_ONE', p_note || CASE WHEN p_note IS NOT NULL THEN '. ' END ||
      'P_BATCH_SKEY='||p_batch_skey||
      ', P_PSUID='||p_psuid||
      ', P_USER='||p_user||' ('||SYS_CONTEXT('USERENV','OS_USER')||')'||
      ', P_COMMIT='||NVL(p_commit, 'NULL') ||
      CASE WHEN p_today <> TRUNC(SYSDATE) THEN ', P_TODAY='||p_today END,
      5, $$PLSQL_UNIT
    );
    
    dt_start := SYSDATE;
    
    psa.process_pers_data
    (
      p_batch_skey        => p_batch_skey, 
      p_psuid             => p_psuid,
      p_userid            => p_user,
      p_supplier_res      => rc_res,
      p_commit            => false,
      p_today             => p_today
    );
    
    CLOSE rc_res;
    
    capture_results;
    
    IF p_commit <> 'Y' THEN ROLLBACK; END IF;
    
    save_results;
    
    IF p_commit IS NOT NULL THEN COMMIT; END IF;
    
    xl.close_log('Completed');
  EXCEPTION
   WHEN OTHERS THEN
    ROLLBACK;
    xl.close_log(sqlerrm, TRUE);
    RAISE;
  END;
  
  
  PROCEDURE run_tests
  (
    p_user          IN VARCHAR2,
    p_test_case     IN VARCHAR2 DEFAULT NULL,
    p_test_num      IN PLS_INTEGER DEFAULT NULL,
    p_commit        IN CHAR DEFAULT 'Y',
    p_today         IN DATE DEFAULT TRUNC(SYSDATE)
  ) IS
    tab_test_cases  tab_v256;
  BEGIN
    IF p_test_case LIKE '%,%' THEN
      tab_test_cases := split_string(p_test_case);
    ELSE
      SELECT DISTINCT test_case BULK COLLECT INTO tab_test_cases
      FROM cnf_tests WHERE test_case LIKE NVL(p_test_case, '%');
    END IF;
    
    FOR r IN 
    (
      SELECT
        test_case, test_num, psuid, batch_skey,
        MAX(test_num) OVER(PARTITION BY test_case) max_test_num
      FROM TABLE(tab_test_cases) tl 
      JOIN cnf_tests t
        ON t.test_case = tl.COLUMN_VALUE
       AND t.test_num = NVL(p_test_num, t.test_num)
      ORDER BY test_case, test_num
    )  
    LOOP  
      IF r.test_num = 1 THEN
        ahmadmin.purge_plan_sponsor_data(r.psuid, p_user);
      END IF;

      UPDATE ods.SupplierBatch SET LoadStatusMnemonic = 'SUPPLIERPRCS_AS_READY'
      WHERE SupplierBatchSkey = r.batch_skey
      AND LoadStatusMnemonic <> 'SUPPLIERPRCS_AS_READY';
      
      UPDATE ods.stg_SupplierControl
      SET RecordStatusmnemonic = NULL, processflg = 'N'
      WHERE SupplierBatchSKEY = r.batch_skey
      AND psuid = r.psuid
      AND (ProcessFLG = 'Y' OR RecordStatusMnemonic IS NOT NULL);

      run_one
      (
        p_batch_skey  => r.batch_skey,
        p_psuid       => r.psuid,
        p_user        => p_user,
        p_commit      => CASE WHEN r.test_num < r.max_test_num THEN 'Y' ELSE p_commit END,
        p_note        => r.test_case||'-'||r.test_num,
        p_today       => p_today
      );
    END LOOP; 
  END;
  
BEGIN
  init;
END;
/
