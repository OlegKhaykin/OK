CREATE OR REPLACE VIEW vw_psa_uat_etlmastersuppl_ovrd AS
WITH
  -- 05-Jan-2021,Sunil Nando: created UAT test view for etlmastersupplieroverride table
  new_op AS
  (
    SELECT --+ materialize
      psl.psuid,
      ems.mastersupplierid, 
      ems.runtype, 
      ems.runtypecd, 
      ems.etldrivercd, 
      ems.exclusioncd 
    FROM vw_psa_plan_sponsor_list                              psl
    JOIN ahmadmin.Supplier                                     sup
      ON sup.psuid = psl.psuid 
    JOIN ahmadmin.SupplierGroup                                sg
      ON sg.SupplierID = sup.SupplierID 
     AND sg.SupplierGroupTypeID = 1 
    JOIN ahmadmin.MasterSupplier                               ms
      ON ms.MasterSupplierID = sg.SupplierGroupID    
    JOIN ods.etlmastersupplieroverride                         ems
      ON ems.mastersupplierid = ms.AHMSupplierID
  ),
  old_op AS
  (
    SELECT --+ materialize
    DISTINCT
      psl.psuid,
      ems.mastersupplierid, 
      ems.runtype, 
      ems.runtypecd, 
      ems.etldrivercd, 
      ems.exclusioncd 
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
    JOIN ahmadmin.SupplierGroup@psa                                       sg
      ON sg.SupplierID = sup.SupplierID 
     AND sg.SupplierGroupTypeID = 1 
    JOIN ahmadmin.MasterSupplier@psa                                      ms
      ON ms.MasterSupplierID = sg.SupplierGroupID    
    JOIN ods.etlmastersupplieroverride@psa                                ems
      ON ems.mastersupplierid = ms.AHMSupplierID
  )
SELECT
  'etlmastersupplieroverride : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'etlmastersupplieroverride : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_etlmastersuppl_ovrd TO deployer, ods_dml;