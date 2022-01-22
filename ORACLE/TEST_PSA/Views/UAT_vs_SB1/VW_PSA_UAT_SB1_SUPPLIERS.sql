CREATE OR REPLACE VIEW vw_psa_uat_sb1_suppliers AS
WITH
  -- 26-Feb-2021, R.Donakonda : Added TRUNC
  -- 05-Jan-2021, O.Khaykin: created
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_data AS
  (
    SELECT --+ materialize
      psl.psuid,
      s.hdmsclientreferenceid,
      s.ceservernm,
      s.mastertypecd,
      s.portalflg,
      s.claimsflg,
      s.healthplanriskid,
      s.populationtypeid,
      s.productionstatusid,
      s.hdmslastfeeddt,
      s.dmfirstfeeddt,
      s.hdmsdeliverybeforedaynm,
      s.hdmsdeliverybeforedaynum,
      s.hdmsdatafrequencyid,
      s.hdmsdeliveryafterdaynm,
      s.hdmsdeliveryafterdaynum,
      s.projectedmembertransferdt,
      s.membertransferrequiredflg,
      s.membertransferreasonid,
      s.hdmsfirstfeeddt,
      s.dmfirstactivitydt,
      TRUNC(s.effectivestartdt),
      TRUNC(s.effectiveenddt),
      s.suppliertypeid,
      s.providerassigmnemonic,
      s.providerassigfreqmnemonic,
      s.defaultbusinesssupplierflg,
      s.usagemnemonic,
      s.pcpdatasourcenm,
      s.relatedahmbusinesssupplierid,
      s.attributedflag,
      s.aetnainternationalflg,
      s.emailconsentflg,
      s.datashareconsentflg,
      s.datasourcenm
    FROM psl
    JOIN ahmadmin.supplier s 
      ON s.psuid = psl.psuid
  )
--select * from new_data
  , old_data AS
  (
    SELECT --+ materialize driving_site(ps)
     DISTINCT
      psl.psuid,
      s.hdmsclientreferenceid,
      s.ceservernm,
      s.mastertypecd,
      s.portalflg,
      s.claimsflg,
      s.healthplanriskid,
      s.populationtypeid,
      s.productionstatusid,
      s.hdmslastfeeddt,
      s.dmfirstfeeddt,
      s.hdmsdeliverybeforedaynm,
      s.hdmsdeliverybeforedaynum,
      s.hdmsdatafrequencyid,
      s.hdmsdeliveryafterdaynm,
      s.hdmsdeliveryafterdaynum,
      s.projectedmembertransferdt,
      s.membertransferrequiredflg,
      s.membertransferreasonid,
      s.hdmsfirstfeeddt,
      s.dmfirstactivitydt,
      TRUNC(s.effectivestartdt),
      TRUNC(s.effectiveenddt),
      s.suppliertypeid,
      s.providerassigmnemonic,
      s.providerassigfreqmnemonic,
      s.defaultbusinesssupplierflg,
      s.usagemnemonic,
      s.pcpdatasourcenm,
      s.relatedahmbusinesssupplierid,
      s.attributedflag,
      s.aetnainternationalflg,
      s.emailconsentflg,
      s.datashareconsentflg,
      s.datasourcenm
    FROM psl
    JOIN ahmadmin.PlanSponsor@sb1                                       ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                            c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
    JOIN ahmadmin.ControlSuffixAccount@sb1                              csa
      ON csa.PlansponsorControlInfoSKEY = c.PlansponsorControlInfoSKEY
    JOIN ahmadmin.SupplierCSAXREF@sb1                                   scx
      ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
    JOIN ahmadmin.supplier@sb1                                          s
      ON s.SupplierID = scx.SupplierID
  )
--select * from old_data
SELECT 'SUPPLIER: NEW minus OLD' AS compare, nmo.*
FROM (SELECT * FROM new_data MINUS SELECT * FROM old_data) nmo
UNION ALL
SELECT 'SUPPLIER: OLD minus NEW' AS compare, omn.*
FROM (SELECT * FROM old_data MINUS SELECT * FROM new_data) omn;

GRANT SELECT ON vw_psa_uat_sb1_suppliers TO deployer, ods_dml, ahmadmin_read;