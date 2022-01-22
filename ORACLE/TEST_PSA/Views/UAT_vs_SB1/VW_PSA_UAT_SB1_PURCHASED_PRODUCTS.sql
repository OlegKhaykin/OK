CREATE OR REPLACE VIEW vw_psa_uat_sb1_purchased_products AS 
WITH
  -- 29-Mar-2021,R.Donakonda: Removed ProductTerminationDT > SYSDATE check from OLD_DATA
  -- 05-Jan-2021, O.Khaykin: created
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_data AS
  (
    SELECT --+ materialize
      psl.psuid, pp.ProductCD, 
      TRUNC(pp.ProductLiveDT)           AS ProductLiveDT, 
      TRUNC(pp.ProductTerminationDT)    AS ProductTerminationDT, 
      TRUNC(pp.ContractEndDT)           AS ContractEndDT,
      pp.AccountID, pp.ProductSettingStatusID, pp.ProductOwner,
      pp.MinRequiredAge, pp.TestSupplierIND,
      pp.AlreadyInProduction, pp.TargetPopulationMnemonic
    FROM psl
    JOIN ahmadmin.supplier s
      ON s.psuid = psl.psuid
    JOIN ahmadmin.purchasedproduct pp
      ON pp.SupplierID = s.SupplierID
  ),
  old_data AS
  (
    SELECT --+ materialize driving_site(ps)
    DISTINCT
      psl.psuid, pp.ProductCD,
      TRUNC(pp.ProductLiveDT)           AS ProductLiveDT, 
      TRUNC(pp.ProductTerminationDT)    AS ProductTerminationDT, 
      TRUNC(pp.ContractEndDT)           AS ContractEndDT,
      pp.AccountID, pp.ProductSettingStatusID, pp.ProductOwner,
      pp.MinRequiredAge, pp.TestSupplierIND,
      pp.AlreadyInProduction, pp.TargetPopulationMnemonic
    FROM psl
    JOIN ahmadmin.PlanSponsor@sb1                                       ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                            c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
    JOIN ahmadmin.ControlSuffixAccount@sb1                              csa
      ON csa.PlansponsorControlInfoSKEY = c.PlansponsorControlInfoSKEY
    JOIN ahmadmin.SupplierCSAXREF@sb1                                   scx
      ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
    JOIN ahmadmin.PurchasedProduct@sb1                                  pp
      ON pp.SupplierID = scx.SupplierID
  )
SELECT 'PurchasedProduct: NEW minus OLD' AS compare, nmo.*
FROM (SELECT * FROM new_data MINUS SELECT * FROM old_data) nmo
UNION ALL
SELECT 'PurchasedProduct: OLD minus NEW' AS compare, omn.*
FROM (SELECT * FROM old_data MINUS SELECT * FROM new_data) omn;

GRANT SELECT ON vw_psa_uat_sb1_purchased_products TO deployer, ods_dml, ahmadmin_read;