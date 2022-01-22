DELETE FROM cnf_data_flows WHERE data_flow_cd IN ('PSA_LOAD_AHDI_CSA_PROCESS');

INSERT INTO cnf_data_flows tgt
(
  data_flow_cd, description,
  max_num_of_jobs, heartbeat_dt, last_proc_id, signal
)
SELECT 'PSA_LOAD_AHDI_CSA_PROCESS', 'Importing Received Suppliers Data from AHDI', 4, SYSDATE, NULL, 'STOP' FROM dual;


INSERT INTO cnf_data_flow_steps
(
  data_flow_cd, set_num, num, operation, tgt, src, match_cols, whr, hint, check_changed,
  generate, del, versions, err_table, commit_at, as_job
) 
SELECT-- DATA_FLOW_CD       SET NUM  OPER        TARGET                                     SOURCE                                      MATCH_COLS            WHERE                                  HINT   CHK_CHNG    GENERATE                                                                       DELETE                       VERS  ERRT                                        CMT  AJ 
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  1,  'UPDATE',   'ODS_LOAD3.AS_SYNC_NATIONAL_ACNT_LOAD',    'AHMADMIN.VW_PSA_AHDI_ERR_AS_SYNC_ACNT',    'ROWID',              NULL,                                  NULL,  NULL,       NULL,                                                                          NULL,                        NULL, NULL,                                       1,   'N' FROM dual UNION ALL SELECT 
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  2,  'INSERT',   'AHMADMIN.PLANSPONSOR',                    'AHMADMIN.VW_PSA_AHDI_PLAN_SPONSOR',         NULL,                NULL,                                  NULL,  NULL,       'PlanSponsorSKEY=AHMADMIN.PlanSponsor_SEQ.NEXTVAL',                            NULL,                        NULL, 'AHMADMIN.Err_PlanSponsor',                 0,   'N' FROM dual UNION ALL SELECT
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  3,  'INSERT',   'AHMADMIN.PSA_CONTROLS',                   'AHMADMIN.VW_PSA_AHDI_PSA_CONTROLS',         NULL,                NULL,                                  NULL,  NULL,       NULL,                                                                          NULL,                        NULL, 'AHMADMIN.Err_PSA_Controls',                0,   'N' FROM dual UNION ALL SELECT 
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  4,  'INSERT',   'AHMADMIN.PSA_BENEFIT_PROVISION_UNITS',    'AHMADMIN.VW_PSA_AHDI_BPU',                  NULL,                NULL,                                  NULL,  NULL,       'bpu_skey=AHMADMIN.ControlSuffixAccount_SEQ.NEXTVAL',                          NULL,                        NULL, 'AHMADMIN.Err_PSA_BPU',                     0,   'N' FROM dual UNION ALL SELECT
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  5,  'INSERT',   'AHMADMIN.PSA_BPU_SUPPLIER_XREF',          'AHMADMIN.VW_PSA_AHDI_BPU_SUPPLIER_XREF',    NULL,                NULL,                                  NULL,  NULL,       'insert_comment=psa.get_parameter(''USERID'')',                                NULL,                        NULL, 'AHMADMIN.Err_PSA_BPU_SUPPLIER_XREF',       0,   'N' FROM dual UNION ALL SELECT
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  6,  'INSERT',   'AHMADMIN.PSA_BPU_BPLV_XREF',              'AHMADMIN.VW_PSA_AHDI_BPU_BPLV_XREF',        NULL,                NULL,                                  NULL,  NULL,       NULL,                                                                          NULL,                        NULL, 'AHMADMIN.Err_PSA_BPU_BPLV_XREF',           0,   'N' FROM dual UNION ALL SELECT
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  7,  'MERGE',    'ODS.CSASUPPLIERXREF',                     'AHMADMIN.VW_PSA_ODS_AHDI_CSASUPPXREF',      'ROWID',             NULL,                                  NULL,  NULL,       NULL,                                                                          NULL,                        NULL, NULL,                                       0,   'N' FROM dual UNION ALL SELECT
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  8,  'UPDATE',   'ODS_LOAD3.AS_SYNC_NATIONAL_ACNT_LOAD',    'AHMADMIN.VW_PSA_AHDI_SUCCES_SYNC_ACNT',     'ROWID',             NULL,                                  NULL,  NULL,       NULL,                                                                          NULL,                        NULL, NULL,                                       0,   'N' FROM dual UNION ALL SELECT 
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  9,  'UPDATE',   'ODS_LOAD3.AS_SYNC_NATIONAL_ACNT_LOAD',    'AHMADMIN.VW_PSA_AHDI_FAIL_SYNC_ACNT',       'ROWID',             NULL,                                  NULL,  NULL,       NULL,                                                                          NULL,                        NULL, NULL,                                       0,   'N' FROM dual UNION ALL SELECT 
'PSA_LOAD_AHDI_CSA_PROCESS', 1,  10, 'MERGE',    'AHMADMIN.PLANSPONSORSUPPLIERRELATION',    'AHMADMIN.VW_PSA_AHDI_PS_SUPPLIER_XREF',     'ROWID',             NULL,                                  NULL,  NULL,       NULL,                                                                          NULL,                        NULL, NULL,                                       0,   'N' FROM dual ;

COMMIT;
