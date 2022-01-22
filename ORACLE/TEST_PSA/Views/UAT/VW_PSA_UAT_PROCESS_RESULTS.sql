CREATE OR REPLACE VIEW vw_psa_uat_process_results AS
WITH
  -- 04-Jan-2020,UAT-Test View A.Kapoor: created
  new_results AS
  (
    SELECT --+ materialize 
      CONTROLID, 
      ACCOUNTID, 
      res.PSUID, 
      SEGMENTCD, 
      SUBSEGMENTCD, 
      ACTIONTYPE,
      SUPPEFFTENDDT, 
      PRODUCTLIST, 
      ISMAHALREADYADDED, 
      ISSYNCWITHCOMMENG,  
      SHOULDSYNCWITHCOMMENG
    FROM AHMADMIN.Psa_Process_Results res
    JOIN vw_psa_plan_sponsor_list     ppsl
      ON res.PSUID = ppsl.PSUID
    WHERE INSERTED_DT >= TO_TIMESTAMP(trunc(sysdate))
  ),      
  old_results AS
  (
    SELECT --+ materialize
      CONTROLID, 
      ACCOUNTID, 
      res.PSUID, 
      SEGMENTCD, 
      SUBSEGMENTCD, 
      ACTIONTYPE, 
      SUPPEFFTENDDT, 
      PRODUCTLIST, 
      ISMAHALREADYADDED, 
      ISSYNCWITHCOMMENG, 
      SHOULDSYNCWITHCOMMENG
    FROM AHMADMIN.Tmp_Psa_Process_Results@psa res
    JOIN vw_psa_plan_sponsor_list             ppsl
      ON res.PSUID = ppsl.PSUID
    WHERE INSERTED_DT >=  TO_TIMESTAMP(trunc(sysdate)) --Get records instered for today only 
  )
SELECT
  'Psa_Process_Results : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'Psa_Process_Results : OLD minus NEW'  AS Compare,
  n.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) n;

GRANT SELECT ON vw_psa_uat_process_results TO deployer, ods_dml, ahmadmin_read;

