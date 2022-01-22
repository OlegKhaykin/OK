CREATE OR REPLACE VIEW vw_psa_uat_supplierextract AS
WITH
  -- 19-Apr-2021,Sunil Nando: Modified to get the data only for latest batch
  -- 06-Jan-2021,Sunil Nando: created UAT test view for SupplierExtract table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid,
     -- se.supplierextractskey,
     -- se.supplierbatchskey,
     -- se.stgsuppliercontrolskey,
      MAX(TRUNC(se.extractcreatedt)) AS extractcreatedt,
      TRUNC(se.extractsentdt)        AS extractsentdt
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ahmadmin.supplier                            sup
      ON sup.psuid = psl.psuid
    JOIN ods.SupplierExtract                          se
      ON se.ahmsupplierID = sup.ahmsupplierID
    GROUP BY psl.psuid,se.extractsentdt
  ),
  old_op AS
  (
    SELECT --+ materialize
    DISTINCT
      psl.psuid,
     -- se.supplierextractskey,
     -- se.supplierbatchskey,
     -- se.stgsuppliercontrolskey,
      MAX(TRUNC(se.extractcreatedt)) AS extractcreatedt,
      TRUNC(se.extractsentdt)        AS extractsentdt
    FROM vw_psa_plan_sponsor_list                                         psl 
    JOIN ahmadmin.plansponsor@psa                                         ps 
      ON ps.plansponsoruniqueid = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@psa                              c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount@psa                                csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@psa                                     scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey
    JOIN ahmadmin.Supplier@psa                                            sup
      ON sup.supplierid = scx.SupplierID
    JOIN ods.SupplierExtract@psa                                          se
      ON se.ahmsupplierID = sup.ahmsupplierID
    GROUP BY psl.psuid,se.extractsentdt
  )
SELECT
  'SupplierExtract : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'SupplierExtract : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_supplierextract TO deployer, ods_dml;