CREATE OR REPLACE VIEW test_psa.vw_psa_tst_new_bpu_bplv AS
SELECT
  -- 29-Jul-2021, OK: moved to TEST_PSA, renamed 2 columns.
  -- 24-Aug-2020, OK: created
  ps.PlanSponsorNM  plan_sponsor_name,
  bpu.bpu_skey, bpu.bpu_cd,
  bplv.BenefitInfoCD||'-'||bplv.ProvisionCD||'-'||bplv.LineValueCD  AS bplv_cd,
  bbx.start_dt, 
  bbx.end_dt,
  LISTAGG
  (
    pbx.ProductCD ||
    CASE
      WHEN pbx.ProductCD = 'MAH' THEN '_'||bplv.LineValueCD
      WHEN pbx.ProductCD = 'AHYW' THEN '_'||pbx.FamilyID
    END,
    ';'
  ) WITHIN GROUP (ORDER BY pbx.ProductCD)                           AS product_list,
  ps.PlanSponsorUniqueID                                            AS psuid
FROM ahmadmin.PlanSponsor                               ps
JOIN ahmadmin.psa_controls                              c
  ON c.psuid = ps.PlanSponsorUniqueID
JOIN ahmadmin.psa_benefit_provision_units               bpu
  ON bpu.psuid = c.psuid
 AND bpu.control_cd = c.control_cd
JOIN ahmadmin.psa_bpu_bplv_xref                         bbx
  ON bbx.bpu_skey = bpu.bpu_skey
JOIN ahmadmin.BenefitProvisionLineValue                 bplv
  ON bplv.BenefitProvLineValID = bbx.bplv_id
 AND bplv.activeflg = 'Y'
JOIN ahmadmin.ProductBPLVXref pbx
  ON pbx.BenefitProvLineValID = bplv.BenefitProvLineValID
 AND pbx.ActiveFLG = 'Y'
GROUP BY
 ps.PlanSponsorNM, bpu.bpu_skey, bpu.bpu_cd, bplv.BenefitInfoCD, bplv.ProvisionCD, bplv.LineValueCD,
 bbx.start_dt, bbx.end_dt, ps.PlanSponsorUniqueID;

GRANT SELECT ON vw_psa_tst_new_bpu_bplv TO ETLAdmin, AHMAdmin_read, AHMAdmin_dml, ods_dml;