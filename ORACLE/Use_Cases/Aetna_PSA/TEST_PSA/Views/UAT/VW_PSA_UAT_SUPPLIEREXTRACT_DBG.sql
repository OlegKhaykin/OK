CREATE OR REPLACE VIEW vw_psa_uat_supplierextract_dbg AS
WITH
  -- 20-Apr-2021, O.Khaykin: minor bug fix. 
  -- 04-Mar-2021, R.Donakonda: created UAT test dbg view for ods.SupplierExtract table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid,
      se.supplierextractskey, se.supplierbatchskey, se.stgsuppliercontrolskey,
      se.ahmsupplierid, se.extractcreatedt, se.extractsentdt, se.inserteddt,
      se.insertedby, se.updateddt, se.updatedby
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ahmadmin.supplier                            sup
      ON sup.psuid = psl.psuid
    JOIN ods.SupplierExtract                          se
      ON se.ahmsupplierID = sup.ahmsupplierID
  ),
  old_op AS
  (
    SELECT /*+ materialize */ DISTINCT
      psl.psuid,
      se.supplierextractskey, se.supplierbatchskey, se.stgsuppliercontrolskey,
      se.ahmsupplierid, se.extractcreatedt, se.extractsentdt, se.inserteddt,
      se.insertedby, se.updateddt, se.updatedby
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
  )
SELECT 'SupplierExtract : NEW'  AS Compare, n.* FROM (SELECT * FROM new_op) n
UNION ALL
SELECT 'SupplierExtract : OLD'  AS Compare, o.* FROM (SELECT * FROM old_op) o;

GRANT SELECT ON vw_psa_uat_supplierextract_dbg TO deployer, ods_dml;