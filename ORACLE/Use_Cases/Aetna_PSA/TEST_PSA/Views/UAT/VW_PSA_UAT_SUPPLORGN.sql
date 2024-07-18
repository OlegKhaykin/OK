CREATE OR REPLACE VIEW vw_psa_uat_supplorgn AS
WITH
  -- 01-Mar-2021,Sunil Nando: Commented orgnm as it is different in OLD and NEW
  -- 15-Jan-2021,Sunil Nando: Formatted and modified old_result code
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
      psl.psuid,
      --so.orgnm,
      so.hdmsclientreferenceid,
      so.sourcealternateuniqueid,
      so.ceservernm,
      TRUNC(so.effectivestartdt) 	AS effectivestartdt,
      TRUNC(so.effectiveenddt)   	AS effectiveenddt,
      so.mastertype,
      so.portalflag,
      so.productionstatus,
      so.zdel_usepcpflag,
      so.claimsflg,
      so.usagemnemonic,
      so.defaultbusinesssupplierflg,
      so.pcpdatasourcenm,
      so.providerassignationcd,
      so.zdel_providerassignationfreq,
      so.relatedahmbusinesssupplierid,
      so.attributedflag,
      so.populationtypemnemonic,
      so.emailconsentflg,
      so.datashareconsentflg,
      so.datasourcenm
    FROM psl                                         
    JOIN ahmadmin.supplier                           s
      ON s.psuid = psl.psuid                        
    JOIN ods.supplierorganization                    so
      ON so.ahmsupplierid = s.ahmsupplierid            
  ),                                                  
  old_results AS                                      
  (                                                   
    SELECT --+ materialize driving_site(ps)
    DISTINCT
      psl.psuid,    
      --so.orgnm,                                       
      so.hdmsclientreferenceid,                       
      so.sourcealternateuniqueid,                     
      so.ceservernm,                                  
      TRUNC(so.effectivestartdt) 	AS effectivestartdt,
      TRUNC(so.effectiveenddt)   	AS effectiveenddt,
      so.mastertype,                                  
      so.portalflag,                                  
      so.productionstatus,                            
      so.zdel_usepcpflag,                             
      so.claimsflg,                                   
      so.usagemnemonic,                               
      so.defaultbusinesssupplierflg,                  
      so.pcpdatasourcenm,                             
      so.providerassignationcd,                       
      so.zdel_providerassignationfreq,                
      so.relatedahmbusinesssupplierid,                
      so.attributedflag,                              
      so.populationtypemnemonic,                      
      so.emailconsentflg,                             
      so.datashareconsentflg,                         
      so.datasourcenm                                 
    FROM psl 
    JOIN ahmadmin.plansponsor@psa                                         ps 
      ON ps.plansponsoruniqueid = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@psa                              c
      ON c.PlanSponsorSKey = ps.PlanSponsorSKey
    JOIN ahmadmin.ControlSuffixAccount@psa                                csa
      ON csa.PlanSponsorControlInfoSKey = c.PlanSponsorControlInfoSKey
    JOIN ahmadmin.SupplierCSAXref@psa                                     scx
      ON scx.ControlSuffixAccountSkey = csa.ControlSuffixAccountSkey    
    JOIN ahmadmin.supplier@psa                                            s   
	    ON s.supplierid = scx.supplierid                             
    JOIN ods.supplierorganization@psa                                     so  
      ON so.ahmsupplierid = s.ahmsupplierid
  )
SELECT
  'VW_PSA_UAT_SUPPLORGN : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'VW_PSA_UAT_SUPPLORGN : OLD minus NEW'  AS Compare,
  n.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) n;

GRANT SELECT ON vw_psa_uat_supplorgn TO deployer, ods_dml;
