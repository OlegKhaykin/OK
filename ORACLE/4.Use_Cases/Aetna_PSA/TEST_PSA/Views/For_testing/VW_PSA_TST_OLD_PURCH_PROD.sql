CREATE OR REPLACE VIEW test_psa.vw_psa_tst_old_purch_prod AS
SELECT
  -- 29-Jul-2021, OK: moved to TEST_PSA.
  -- 01-Sep-2020, OK: used DISTINCT for PlanSponsor-Supplier maoing and a sub-query for SupplierGroup
  -- 24-Aug-2020, OK: created
  psp.*,
  ms.MasterSupplierNM,
  s.SupplierNM,
  s.EffectiveStartDT, 
  s.EffectiveEndDT, 
  s.product_list,
  pp.ProductCD, 
  pp.ProductLiveDT, 
  pp.ProductTerminationDT,
  pp.ProductSettingStatusID
FROM
(
  SELECT DISTINCT
    ps.PlanSponsorUniqueID          psuid,
    ps.PlanSponsorNM                plan_sponsor_name,
    scx.SupplierID 
  FROM ahmadmin.PlanSponsor                                             ps
  JOIN ahmadmin.PlanSponsorControlInfo                                  c
    ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
  JOIN ahmadmin.ControlSuffixAccount                                    csa
    ON csa.PlanSponsorControlInfoSKEY = c.PlanSponsorControlInfoSKEY  
  JOIN ahmadmin.SupplierCSAXref                                         scx
    ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
) psp
JOIN ahmadmin.Supplier                                                  s
  ON s.SupplierID = psp.SupplierID
JOIN ahmadmin.PurchasedProduct                                          pp
  ON pp.SupplierID = s.SupplierID
LEFT JOIN
(
  SELECT SupplierID, MIN(SupplierGroupID) SupplierGroupID
  FROM ahmadmin.SupplierGroup
  WHERE SupplierGroupTypeID = 1
  GROUP BY SupplierID
)                                                                       sg
  ON sg.SupplierID = s.SupplierID
LEFT JOIN ahmadmin.MasterSupplier                                       ms
  ON ms.MasterSupplierID = sg.SupplierGroupID;

GRANT SELECT ON vw_psa_tst_old_purch_prod TO ETLAdmin, AHMAdmin_read, AHMAdmin_dml, ods_dml;
