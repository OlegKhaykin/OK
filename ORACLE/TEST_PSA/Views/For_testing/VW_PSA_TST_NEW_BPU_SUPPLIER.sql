CREATE OR REPLACE VIEW test_psa.vw_psa_tst_new_bpu_supplier AS
SELECT
  -- 29-Jul-2021, OK: moved to TEST_PSA.
  -- 24-Aug-2020, OK: created
  ps.PlanSponsorNM  plan_sponsor_name,
  bpu.bpu_skey,
  bpu.bpu_cd,
  bsx.start_dt                                                      AS bpu_supp_start_dt, 
  bsx.end_dt                                                        AS bpu_supp_end_dt,
  s.SupplierID, s.SupplierNM,
  ps.PlanSponsorUniqueID                                            AS psuid
FROM ahmadmin.PlanSponsor                       ps
JOIN ahmadmin.psa_controls                      c
  ON c.psuid = ps.PlanSponsorUniqueID
JOIN ahmadmin.psa_benefit_provision_units       bpu
  ON bpu.psuid = c.psuid
 AND bpu.control_cd = c.control_cd
JOIN ahmadmin.psa_bpu_supplier_xref             bsx
  ON bsx.bpu_skey = bpu.bpu_skey
JOIN ahmadmin.supplier                          s
  ON s.supplierid = bsx.supplier_id;

GRANT SELECT ON vw_psa_tst_new_bpu_supplier TO ETLAdmin, AHMAdmin_read, AHMAdmin_dml, ods_dml;