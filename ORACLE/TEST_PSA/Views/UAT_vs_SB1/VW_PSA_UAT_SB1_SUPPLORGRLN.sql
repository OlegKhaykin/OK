CREATE OR REPLACE VIEW vw_psa_uat_sb1_supplorgrln AS
WITH
  -- 15-Jan-2021,Sunil Nando: Formatted and did some minor changes
  -- 12-Jan-2021,Review comments incorporated : Srinivas MR : modified
  -- 06-Jan-2020,UAT-Test View Srinivas MR : created
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.PSUID,
      sog.orgid                           AS orgid,
      sog.orgrelationtypeid               AS orgrelationtypeid,
      sog.deliveryfrequencymnemonic       AS deliveryfrequencymnemonic
    FROM psl                                      
    JOIN ahmadmin.supplier                        s 
      ON s.psuid = psl.psuid                     
    JOIN ahmadmin.supplierorgrelation             sog
      ON sog.supplierid = s.supplierid
  ),      
  old_results AS
  (
   SELECT --+ materialize driving_site(psl)
   DISTINCT
     psl.PSUID,
     sog.orgid                          AS orgid,
     sog.orgrelationtypeid              AS orgrelationtypeid,
     sog.deliveryfrequencymnemonic      AS deliveryfrequencymnemonic
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
    JOIN ahmadmin.supplierorgrelation@sb1                               sog
      ON sog.supplierid = s.supplierid
  )
SELECT
  'Supplierorgrelation : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'Supplierorgrelation : OLD minus NEW'  AS Compare,
  n.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) n;

GRANT SELECT ON vw_psa_uat_sb1_supplorgrln TO deployer, ods_dml;