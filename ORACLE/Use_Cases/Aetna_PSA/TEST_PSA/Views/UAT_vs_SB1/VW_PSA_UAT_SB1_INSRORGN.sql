CREATE OR REPLACE VIEW vw_psa_uat_sb1_insrorgn AS
WITH
  -- 15-Jan-2021,Sunil Nando: Formatted,added psuid and did some minor changes
  -- 12-Jan-2021,Review comments incorporated : Srinivas MR : modified
  -- 06-Jan-2021,UAT-Test View Srinivas MR : created
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.PSUID,
      io.orgnm                          AS orgnm,
      io.sourcealternateuniqueid        AS sourcealternateuniqueid,
      TRUNC(io.effectivestartdt)        AS effectivestartdt,
      TRUNC(io.effectiveenddt)          AS effectiveenddt,
      io.processingmodecd               AS processingmodecd,
      io.orgid                          AS orgid,
      io.projectid                      AS projectid,
      io.masterfeedflg                  AS masterfeedflg,
      io.financefeedflg	                AS financefeedflg
    FROM psl              
    JOIN ahmadmin.supplier                        s 
      ON s.psuid = psl.psuid                     
    JOIN ahmadmin.supplierorgrelation             so
      ON so.supplierid = s.supplierid             
    JOIN ods.insuranceorganization                io 
      ON io.insuranceorgid = so.orgid
  ),      
  old_results AS
  (
    SELECT --+ materialize driving_site(ps)
    DISTINCT
      psl.PSUID,
      io.orgnm                                       AS orgnm,
      io.sourcealternateuniqueid                     AS sourcealternateuniqueid,
      TRUNC(io.effectivestartdt)                     AS effectivestartdt,
      TRUNC(io.effectiveenddt)                       AS effectiveenddt,
      io.processingmodecd                            AS processingmodecd,
      io.orgid                                       AS orgid,
      io.projectid                                   AS projectid,
      io.masterfeedflg                               AS masterfeedflg,
      io.financefeedflg                              AS financefeedflg
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
    JOIN ahmadmin.supplierorgrelation@sb1                               so
      ON so.supplierid = s.SupplierID
    JOIN ods.insuranceorganization@sb1                                  io 
      ON io.insuranceorgid = so.orgid
  )
SELECT
  'INSURANCEORGANIZATION : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'INSURANCEORGANIZATION : OLD minus NEW'  AS Compare,
  n.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) n;

GRANT SELECT ON vw_psa_uat_sb1_insrorgn TO deployer, ods_dml;