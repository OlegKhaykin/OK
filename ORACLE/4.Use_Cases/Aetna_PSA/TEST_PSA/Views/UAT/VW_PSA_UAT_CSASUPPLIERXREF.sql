CREATE OR REPLACE VIEW vw_psa_uat_csasupplierxref AS
WITH
  -- 05-Jan-2021,Sunil Nando: created UAT test view for CSASupplierxref table
  new_op AS
  (
    SELECT --+ materialize
      csx.psuid,csx.ctrlsuffixacntid,csx.plansummarycd,csx.bplvlist,csx.ahmproductlist,
      csx.segmentnm,csx.subsegmentnm,csx.solesrcflg,TRUNC(csx.startdt) AS startdt,
      TRUNC(csx.enddt) AS enddt,csx.productcd,csx.ahcind,csx.ahcstartdt,csx.contractstate,
      csx.fundingtypemnemonic,csx.controlnm 
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ods.csasupplierxref                          csx
      ON csx.psuid = psl.psuid
  ),
  old_op AS
  (
    SELECT --+ materialize
      csx.psuid,csx.ctrlsuffixacntid,csx.plansummarycd,csx.bplvlist,csx.ahmproductlist,
      csx.segmentnm,csx.subsegmentnm,csx.solesrcflg,TRUNC(csx.startdt) AS startdt,
      TRUNC(csx.enddt) AS enddt,csx.productcd,csx.ahcind,csx.ahcstartdt,csx.contractstate,
      csx.fundingtypemnemonic,csx.controlnm
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ods.csasupplierxref@psa                      csx
      ON csx.psuid = psl.psuid
  )
SELECT
  'CSASupplierxref : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'CSASupplierxref : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_csasupplierxref TO deployer, ods_dml;