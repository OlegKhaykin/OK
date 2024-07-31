CREATE OR REPLACE VIEW vw_psa_uat_sb1_mstrsuplrrln_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.mastersuppliersupplierrelation table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.Psuid,msrln.*
    FROM psl                                           
    JOIN ahmadmin.supplier                             s 
      ON s.psuid = psl.psuid         
    JOIN ods.supplierorganization                      sog 
	    ON sog.ahmsupplierid = s.ahmsupplierid         
    JOIN ods.mastersuppliersupplierrelation            msrln 
	    ON msrln.supplierid = sog.supplierorgid
  ),      
  old_results AS
  (
   SELECT --+ materialize driving_site(ps)
   DISTINCT  psl.Psuid,msrln.*
   FROM psl                                                             
   JOIN ahmadmin.PlanSponsor@sb1                                        ps
     ON ps.PlanSponsorUniqueID = psl.psuid
   JOIN ahmadmin.PlanSponsorControlInfo@sb1                             c
     ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
   JOIN ahmadmin.ControlSuffixAccount@sb1                               csa
     ON csa.PlansponsorControlInfoSKEY = c.PlansponsorControlInfoSKEY
   JOIN ahmadmin.SupplierCSAXREF@sb1                                    scx
     ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
   JOIN ahmadmin.supplier@sb1                                           s
     ON s.SupplierID = scx.SupplierID          
   JOIN ods.supplierorganization@sb1                                    sog
     ON sog.ahmsupplierid = s.ahmsupplierid          
   JOIN ods.mastersuppliersupplierrelation@sb1                          msrln
     ON msrln.supplierid = sog.supplierorgid
  )
SELECT 'MASTERSUPPLIERSUPPLIERRELATION : NEW'  AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'MASTERSUPPLIERSUPPLIERRELATION : OLD'  AS Compare, n.* FROM (SELECT * FROM old_results) n;

GRANT SELECT ON vw_psa_uat_sb1_mstrsuplrrln_dbg TO deployer, ods_dml;