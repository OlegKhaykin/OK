CREATE OR REPLACE VIEW vw_psa_uat_familysupp_xr AS
WITH
  -- 04-Jan-2021,UAT-Test View R.Donakonda: created
  new_results AS
  (
    SELECT --+ materialize
      ppsl.psuid,
      FamilyID
    FROM vw_psa_plan_sponsor_list                                          ppsl 
    JOIN ahmadmin.supplier                                                 sup
      ON sup.psuid = ppsl.psuid
    JOIN ahmadmin.FamilySupplierXREF                                       fsx
      ON fsx.SupplierID = sup.SupplierID 
  ),
  old_results AS
  (
    SELECT  --+ materialize
    DISTINCT
      ppsl.psuid,
      FamilyID
    FROM vw_psa_plan_sponsor_list                                          ppsl
    JOIN ahmadmin.plansponsor@psa                                          ps 
      ON ps.plansponsoruniqueid = ppsl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@psa                               c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount@psa                                 csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@psa                                      scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey
    JOIN ahmadmin.Supplier@psa                                             sup
      ON sup.supplierid = scx.SupplierID
    JOIN ahmadmin.FamilySupplierXREF@psa                                   fsx
      ON fsx.SupplierID = sup.SupplierID  
  )
SELECT
  'FamilySupplierXREF : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'FamilySupplierXREF : OLD minus NEW'  AS Compare,
  o.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) o;

GRANT SELECT ON vw_psa_uat_familysupp_xr TO deployer, ods_dml;
