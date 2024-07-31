CREATE OR REPLACE VIEW vw_psa_uat_sb1_csasupplier_xr AS
WITH
  -- 03-Feb-2021,UAT-Test View R.Donakonda: created
  new_results AS
  (
    SELECT --+ materialize
      controlid,
      suffixid,
      accountid,
      CtrlSuffixAcnt,
      SegmentCD,
      SubSegmentCD,
      PlanSummaryCd,
      EffectiveStartDt,
      EffectiveEndDt,
      MastersupplierID,
      AHMMasterSupplierID,
      FundingTypeMnemonic,
      SupplierSegmentMnemonic,
      ControlNM,
      ContractState,
      BPLVlist,
      ProductList
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.vw_csasupplierxref_new                                   csa
      ON csa.PlanSponsorUniqueId = ppsl.psuid   
  ),
  old_results AS
  (
    SELECT --+ materialize
      controlid,
      suffixid,
      accountid,
      CtrlSuffixAcnt,
      SegmentCD,
      SubSegmentCD,
      PlanSummaryCd,
      EffectiveStartDt,
      EffectiveEndDt,
      MastersupplierID,
      AHMMasterSupplierID,
      FundingTypeMnemonic,
      SupplierSegmentMnemonic,
      ControlNM,
      ContractState,
      BPLVlist,
      ProductList
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.vw_csasupplierxref_old@sb1                               csa
      ON csa.PlanSponsorUniqueId = ppsl.psuid    
  )
SELECT
  'vw_csasupplierxref : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'vw_csasupplierxref : OLD minus NEW'  AS Compare,
  o.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) o;

GRANT SELECT ON vw_psa_uat_sb1_csasupplier_xr TO deployer, ods_dml;
