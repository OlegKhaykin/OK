CREATE OR REPLACE VIEW test_psa.vw_psa_tst_old_bpu_supplier AS
SELECT
  -- 29-Jul-2021, OK: moved to TEST_PSA.
  -- 24-Aug-2020, OK: created
  ps.PlanSponsorNM                                                            AS plan_sponsor_name,
  csa.ControlSuffixAccountSKEY                                                AS csa_skey,
  ps.PlanSponsorUniqueID||'-'||csa.CtrlSuffixAcnt||'-'||scx.PlanSummaryCD     AS bpu_cd,
  TRUNC(scx.EffectiveStartDT)                                                 AS supp_csa_start_dt,
  TRUNC(scx.EffectiveEndDT)                                                   AS supp_csa_end_dt,
  s.SupplierID, s.SupplierNM,   
  ps.PlanSponsorUniqueID                                                      AS psuid
FROM ahmadmin.PlanSponsor                                             ps
JOIN ahmadmin.PlanSponsorControlInfo                                  c
  ON c.PlanSponsorSKEY = ps.plansponsorskey
JOIN ahmadmin.ControlSuffixAccount                                    csa
  ON csa.PlanSponsorControlInfoSKEY = c.PlanSponsorControlInfoSKEY  
JOIN ahmadmin.SupplierCSAXref                                         scx
  ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
JOIN ahmadmin.Supplier                                                s
  ON s.SupplierID = scx.SupplierID;

GRANT SELECT ON vw_psa_tst_old_bpu_supplier TO ETLAdmin, AHMAdmin_read, AHMAdmin_dml, ods_dml;
