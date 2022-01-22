CREATE OR REPLACE VIEW vw_psa_uat_sb1_process_results_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for Psa_Process_Results table
  new_results AS
  (
    SELECT --+ materialize 
      res.PsuID,
      SupplierID,
      AHMsupplierID,
      suppliernm,
      ControlID, 
      AccountID, 
      SegmentCD, 
      SubsegmentCD, 
      Actiontype,
      SuppefftendDT, 
      Productlist, 
      ISmahalreadyadded, 
      ISsyncwithcommENG,  
      Shouldsyncwithcommeng
    FROM AHMADMIN.Psa_Process_Results res
    JOIN vw_psa_plan_sponsor_list     ppsl
      ON res.PSUID = ppsl.PSUID
    WHERE INSERTED_DT >= TO_TIMESTAMP(TRUNC(SYSDATE))
  ),      
  old_results AS
  (
    SELECT --+ materialize
      res.PsuID,
      SupplierID,
      AHMsupplierID,
      suppliernm,
      ControlID, 
      AccountID, 
      SegmentCD, 
      SubsegmentCD, 
      Actiontype,
      SuppefftendDT, 
      Productlist, 
      ISmahalreadyadded, 
      ISsyncwithcommENG,  
      Shouldsyncwithcommeng
    FROM AHMADMIN.Tmp_Psa_Process_Results@sb1 res
    JOIN vw_psa_plan_sponsor_list             ppsl
      ON res.PSUID = ppsl.PSUID
    WHERE INSERTED_DT >=  TO_TIMESTAMP(TRUNC(SYSDATE)) --Get records instered for today only 
  )
SELECT 'Psa_Process_Results : NEW' AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'Psa_Process_Results : OLD' AS Compare, n.* FROM (SELECT * FROM old_results) n;

GRANT SELECT ON vw_psa_uat_sb1_process_results_dbg TO deployer, ods_dml;
