CREATE OR REPLACE VIEW vw_psa_uat_sb1_csa_vs_bpu_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for BPU table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_data AS
  (
    SELECT --+ materialize
      psl.psuid,
      bpu.bpu_skey,
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
      csa.ControlSuffixAccountSKEY            AS bpu_skey,
      c.ControlID                             AS control_cd,
      csa.SuffixID                            AS suffix_cd,
      csa.AccountID                           AS account_cd,
      scx.PlanSummaryCD                       AS plan_cd,
      scx.FundingTypeMnemonic                 AS funding_type
    FROM psl
    JOIN ahmadmin.PlanSponsor@sb1                                       ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                            c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
    JOIN ahmadmin.ControlSuffixAccount@sb1                              csa
      ON csa.PlanSponsorControlInfoSKEY = c.PlanSponsorControlInfoSKEY
    JOIN ahmadmin.SupplierCSAXREF@sb1                                   scx
      ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
  )
SELECT 'PSA_BENEFIT_PROVISION_UNITS' AS compare, n.* FROM (SELECT * FROM new_data) n
UNION ALL
SELECT 'CONTROLSUFFIXACCOUNT' AS compare, o.* FROM (SELECT * FROM old_data) o;

GRANT SELECT ON vw_psa_uat_sb1_csa_vs_bpu_dbg TO deployer, ods_dml, ahmadmin_read;
