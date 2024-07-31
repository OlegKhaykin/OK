CREATE OR REPLACE VIEW vw_psa_uat_csa_vs_bpu AS
WITH
  -- 05-Jan-2021, O.Khaykin: created.
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_data AS
  (
    SELECT --+ materialize
      psl.psuid,
      bpu.control_cd,
      bpu.suffix_cd,
      bpu.account_cd,
      bpu.plan_cd,
      bpu.funding_type
    FROM psl
    JOIN ahmadmin.psa_benefit_provision_units   bpu
      ON bpu.psuid = psl.psuid
  ),
  old_data AS
  (
    SELECT --+ materialize driving_site(ps)
      DISTINCT
      psl.psuid,
      c.ControlID                             AS control_cd,
      csa.SuffixID                            AS suffix_cd,
      csa.AccountID                           AS account_cd,
      scx.PlanSummaryCD                       AS plan_cd,
      scx.FundingTypeMnemonic                 AS funding_type
    FROM psl
    JOIN ahmadmin.PlanSponsor@psa                                       ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@psa                            c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
    JOIN ahmadmin.ControlSuffixAccount@psa                              csa
      ON csa.PlanSponsorControlInfoSKEY = c.PlanSponsorControlInfoSKEY
    JOIN ahmadmin.SupplierCSAXREF@psa                                   scx
      ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
  )
SELECT 'PSA_BENEFIT_PROVISION_UNITS minus CONTROLSUFFIXACCOUNT' AS compare, nmo.*
FROM (SELECT * FROM new_data MINUS SELECT * FROM old_data) nmo
UNION ALL
SELECT 'CONTROLSUFFIXACCOUNT minus PSA_BENEFIT_PROVISION_UNITS' AS compare, omn.*
FROM (SELECT * FROM old_data MINUS SELECT * FROM new_data) omn;

GRANT SELECT ON vw_psa_uat_csa_vs_bpu TO deployer, ods_dml, ahmadmin_read;
