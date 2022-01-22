CREATE OR REPLACE VIEW vw_psa_uat_ods_supp_pgrmreln AS
WITH
  -- 04-Jan-2020,UAT-Test View A.Kapoor: created
  new_results AS
  (
    SELECT --+ materialize
      s.psuid,
      Control_Cd,
      Suffix_Cd,
      Account_Cd,
      Plan_Cd,
      spgrm.Productcd, 
      spgrm.Programtypecd, 
      spgrm.Programlivedt, 
      spgrm.Programterminationdt, 
      spgrm.Minrequiredage, 
      spgrm.Ceproductmnemoniccd 
    FROM ODS.Supplierprogramrelation               spgrm
    JOIN ods.SupplierProductRelation               spr
      ON spr.Supplierproductrelskey = spgrm.Supplierproductrelskey
    JOIN ODS.Supplierorganization                  so
      ON so.supplierorgid = spr.supplierorgid
    JOIN ahmadmin.Supplier                         s
      ON s.AHMSupplierID = so.AhmSupplierID
    JOIN vw_psa_plan_sponsor_list                  ppsl
      ON ppsl.psuid = s.psuid
    JOIN ahmadmin.psa_bpu_supplier_xref            pbx
      ON pbx.Supplier_ID = s.SupplierID
    JOIN ahmadmin.psa_benefit_provision_units      pbpu
      ON pbpu.bpu_skey = pbx.bpu_skey  
  ),      
  old_results AS
  (
    SELECT --+ materialize
      p.PlanSponsorUniqueId AS PSUID,
      Controlid,
      Suffixid,
      Accountid,
      Plansummarycd,
      spgrm.Productcd, 
      spgrm.Programtypecd, 
      spgrm.Programlivedt, 
      spgrm.Programterminationdt, 
      spgrm.Minrequiredage, 
      spgrm.Ceproductmnemoniccd  
    FROM ODS.Supplierprogramrelation@psa               spgrm
    JOIN ods.SupplierProductRelation@psa               spr
      ON spr.Supplierproductrelskey = spgrm.Supplierproductrelskey
    JOIN ODS.Supplierorganization@psa                  so
      ON so.supplierorgid = spr.supplierorgid
    JOIN ahmadmin.Supplier@psa                         s
      ON s.AHMSupplierID = so.AhmSupplierID
    JOIN ahmadmin.SupplierCSAXref@psa                  scx  
      ON scx.SupplierID = s.SupplierID
    JOIN ahmadmin.ControlSuffixAccount@psa             csa 
      ON csa.ControlSuffixAccountSkey = scx.ControlSuffixAccountSkey   
    JOIN ahmadmin.PlanSponsorControlInfo@psa           c 
      ON c.Plansponsorcontrolinfoskey = csa.Plansponsorcontrolinfoskey  
    JOIN ahmadmin.plansponsor@psa                      p 
      ON p.PlanSponsorSKEY = c.PlanSponsorSKEY 
    JOIN vw_psa_plan_sponsor_list                      ppsl
      ON ppsl.psuid = p.PlanSponsorUniqueId
  )
SELECT
  'ODS.SupplierProgramRelation : NEW minus OLD'  AS Compare,
  n.* 
FROM (SELECT * FROM new_results MINUS SELECT * FROM old_results) n
UNION ALL
SELECT
  'ODS.SupplierProgramRelation : OLD minus NEW'  AS Compare,
  n.* 
FROM (SELECT * FROM old_results MINUS SELECT * FROM new_results) n;

GRANT SELECT ON vw_psa_uat_ods_supp_pgrmreln TO deployer, ods_dml, ahmadmin_read;
