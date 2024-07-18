CREATE OR REPLACE VIEW test_psa.vw_psa_tst_old_bpu_bplv AS
SELECT
  -- 29-Jul-2021, OK: moved to TEST_PSA, added more columns.
  -- 24-Aug-2020, OK: created
  ps.PlanSponsorNM                                                            AS plan_sponsor_name,
  csa.ControlSuffixAccountSKEY                                                AS csa_skey,
  ps.PlanSponsorUniqueID||'-'||csa.CtrlSuffixAcnt||'-'||scx.PlanSummaryCD     AS bpu_cd,
  bplv.BenefitInfoCD||'-'||bplv.ProvisionCD||'-'||bplv.LineValueCD            AS bplv_cd,
  scx.SupplierID                                                              AS supplier_id,
  TRUNC(scx.EffectiveStartDT)                                                 AS supp_csa_start_dt,
  TRUNC(scx.EffectiveEndDT)                                                   AS supp_csa_end_dt,
  TRUNC(cbx.BPLVStartDT)                                                      AS bplv_start_dt,
  TRUNC(cbx.BPLVEndDT)                                                        AS bplv_end_dt,
  ps.PlanSponsorUniqueID                                                      AS psuid
FROM ahmadmin.PlanSponsor                                               ps
JOIN ahmadmin.PlanSponsorControlInfo                                    c
  ON c.PlanSponsorSKEY = ps.plansponsorskey
JOIN ahmadmin.ControlSuffixAccount                                      csa
  ON csa.PlanSponsorControlInfoSKEY = c.PlanSponsorControlInfoSKEY  
JOIN ahmadmin.SupplierCSAXref                                           scx
  ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
JOIN ahmadmin.CSABPLVXREF                                               cbx
  ON cbx.ControlSuffixAccountSKEY = scx.ControlSuffixAccountSKEY
 AND cbx.PlanSummaryCD = scx.PlanSummaryCD
 AND cbx.EffectiveStartDT = scx.EffectiveStartDT
JOIN ahmadmin.BenefitProvisionLineValue                                 bplv
  ON bplv.BenefitProvLineValID = cbx.BenefitProvLineValID;

GRANT SELECT ON vw_psa_tst_old_bpu_bplv TO ETLAdmin, AHMAdmin_read, AHMAdmin_dml, ods_dml;
