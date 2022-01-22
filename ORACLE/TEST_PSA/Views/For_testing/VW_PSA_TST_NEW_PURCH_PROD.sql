CREATE OR REPLACE VIEW test_psa.vw_psa_tst_new_purch_prod AS
SELECT
  -- 29-Jul-2021, OK: moved to TEST_PSA.
  -- 28-Aug-2020, OK: workaround SupplierGroup population problem
  -- 24-Aug-2020, OK: created
  ps.PlanSponsorUniqueID    psuid,
  ps.PlanSponsorNM          plan_sponsor_name,
  ms.MasterSupplierNM, s.SupplierID, s.SupplierNM,
  s.EffectiveStartDT, s.EffectiveEndDT, s.product_list,
  pp.ProductCD, pp.ProductLiveDT, pp.ProductTerminationDT, pp.ProductSettingStatusID
FROM ahmadmin.PlanSponsor                          ps
JOIN ahmadmin.supplier                             s
  ON s.psuid = ps.PlanSponsorUniqueID     
JOIN ahmadmin.PurchasedProduct                     pp
  ON pp.SupplierID = s.SupplierID         
LEFT JOIN 
(
  SELECT
    SupplierID, 
    MIN(SupplierGroupID) AS SupplierGroupID
  FROM ahmadmin.SupplierGroup
  WHERE SupplierGroupTypeID = 1
  GROUP BY SupplierID
) sg
  ON sg.SupplierID = s.SupplierID         
LEFT JOIN ahmadmin.MasterSupplier                  ms
  ON ms.MasterSupplierID = sg.SupplierGroupID;

GRANT SELECT ON vw_psa_tst_new_purch_prod TO ETLAdmin, AHMAdmin_read, AHMAdmin_dml, ods_dml;
