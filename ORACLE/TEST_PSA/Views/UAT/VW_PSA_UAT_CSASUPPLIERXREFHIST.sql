CREATE OR REPLACE VIEW vw_psa_uat_csasupplierxrefhist AS
WITH
  -- 05-Jan-2021,Sunil Nando: created UAT test view for CSASupplierXrefHist table
  new_op AS
  (
    SELECT --+ materialize
      csxh.psuid,csxh.newpsuid,csxh.ctrlsuffixacntid,csxh.plansummarycd,csxh.bplvlist,
      csxh.ahmproductlist,csxh.segmentnm,csxh.subsegmentnm,csxh.solesrcflg,
      TRUNC(csxh.startdt) AS startdt,TRUNC(csxh.enddt) AS enddt,csxh.productcd,
      csxh.ahcind,csxh.ahcstartdt,csxh.contractstate,csxh.fundingtypemnemonic,
      csxh.controlnm,csxh.psuname,csxh.newpsuname 
    FROM vw_psa_plan_sponsor_list                     psl 
    JOIN ods.CSASupplierXrefHist                      csxh
      ON (csxh.psuid = psl.psuid OR csxh.newpsuid = psl.psuid)
  ),
  old_op AS
  (
    SELECT --+ materialize
      csxh.psuid,csxh.newpsuid,csxh.ctrlsuffixacntid,csxh.plansummarycd,csxh.bplvlist,
      csxh.ahmproductlist,csxh.segmentnm,csxh.subsegmentnm,csxh.solesrcflg,
      TRUNC(csxh.startdt) AS startdt,TRUNC(csxh.enddt) AS enddt,csxh.productcd,
      csxh.ahcind,csxh.ahcstartdt,csxh.contractstate,csxh.fundingtypemnemonic,
      csxh.controlnm,csxh.psuname,csxh.newpsuname
    FROM vw_psa_plan_sponsor_list                         psl 
    JOIN ods.CSASupplierXrefHist@psa                      csxh
      ON (csxh.psuid = psl.psuid OR csxh.newpsuid = psl.psuid)
  )
SELECT
  'CSASupplierXrefHist : NEW minus OLD'  AS Compare,
  nmo.* 
FROM (SELECT * FROM new_op MINUS SELECT * FROM old_op) nmo
UNION ALL
SELECT
  'CSASupplierXrefHist : OLD minus NEW'  AS Compare,
  omn.* 
FROM (SELECT * FROM old_op MINUS SELECT * FROM new_op) omn;

GRANT SELECT ON vw_psa_uat_csasupplierxrefhist TO deployer, ods_dml;