CREATE OR REPLACE VIEW vw_psa_uat_sb1_bpu_bplv_xref_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for BPU-BPLV table
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
      bpu.bpu_cd,
      bplv.benefitinfocd||'-'||bplv.provisioncd||'-'||bplv.linevaluecd         AS bplv_cd,
      bbx.start_dt, bbx.end_dt
    FROM psl
    JOIN ahmadmin.psa_benefit_provision_units     bpu
      ON bpu.psuid = psl.psuid
    JOIN ahmadmin.psa_bpu_bplv_xref               bbx
      ON bbx.bpu_skey = bpu.bpu_skey
    JOIN ahmadmin.benefitprovisionlinevalue       bplv
      ON bplv.BenefitProvLineValID = bbx.bplv_id
  ),
  old_data AS
  (
    SELECT --+ materialize driving_site(ps)
      psl.psuid,
      cbx.ControlSuffixAccountSKEY                                              AS bpu_skey,
      ps.plansponsoruniqueid||'-'||csa.CtrlSuffixAcnt||'-'||cbx.plansummarycd   AS bpu_cd,
      bplv.benefitinfocd||'-'||bplv.provisioncd||'-'||bplv.linevaluecd          AS bplv_cd, 
      TRUNC(cbx.BPLVStartDT)                                                    AS start_dt,
      NVL(TRUNC(cbx.BPLVEndDT)+1, DATE '9999-12-31')                            AS end_dt
    FROM psl
    JOIN ahmadmin.PlanSponsor@sb1                                       ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                            c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
    JOIN ahmadmin.ControlSuffixAccount@sb1                              csa
      ON csa.PlansponsorControlInfoSKEY = c.PlansponsorControlInfoSKEY
    JOIN ahmadmin.SupplierCSAXREF@sb1                                   scx
      ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
    JOIN ahmadmin.CSABPLVXREF@sb1                                       cbx
      ON cbx.ControlSuffixAccountSKEY = scx.ControlSuffixAccountSKEY
     AND cbx.PlanSummaryCD = scx.PlanSummaryCD
     AND cbx.EffectiveStartDT = scx.EffectiveStartDT
    JOIN ahmadmin.BenefitProvisionLineValue@sb1                         bplv
      ON bplv.BenefitProvLineValID = cbx.BenefitProvLineValID
  )
SELECT 'PSA_BPU_BPLV_XREF' AS compare, n.* FROM (SELECT * FROM new_data) n
UNION ALL
SELECT 'CSABPLVXREF' AS compare, o.* FROM (SELECT * FROM old_data) o;

GRANT SELECT ON vw_psa_uat_sb1_bpu_bplv_xref_dbg TO deployer, ods_dml, ahmadmin_read;
