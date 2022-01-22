CREATE OR REPLACE VIEW vw_psa_uat_sb1_supplorgn_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for ods.supplierorganization table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_results AS
  (
    SELECT --+ materialize
      psl.psuid, so.*
    FROM psl                                         
    JOIN ahmadmin.supplier                           s
      ON s.psuid = psl.psuid                        
    JOIN ods.supplierorganization                    so
      ON so.ahmsupplierid = s.ahmsupplierid            
  ),                                                  
  old_results AS                                      
  (                                                   
    SELECT --+ materialize driving_site(ps)
    DISTINCT psl.psuid, so.*                              
    FROM psl 
    JOIN ahmadmin.plansponsor@sb1                                         ps 
      ON ps.plansponsoruniqueid = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                              c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount@sb1                                csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@sb1                                     scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey    
    JOIN ahmadmin.supplier@sb1                                            s   
	    ON s.supplierid = scx.supplierid                             
    JOIN ods.supplierorganization@sb1                                     so  
      ON so.ahmsupplierid = s.ahmsupplierid
  )
SELECT 'VW_PSA_UAT_SUPPLORGN : NEW' AS Compare, n.* FROM (SELECT * FROM new_results) n
UNION ALL
SELECT 'VW_PSA_UAT_SUPPLORGN : OLD' AS Compare, o.* FROM (SELECT * FROM old_results) o;

GRANT SELECT ON vw_psa_uat_sb1_supplorgn_dbg TO deployer, ods_dml;
