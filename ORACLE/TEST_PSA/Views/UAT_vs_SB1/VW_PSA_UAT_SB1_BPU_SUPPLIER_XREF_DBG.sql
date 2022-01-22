CREATE OR REPLACE VIEW vw_psa_uat_sb1_bpu_supplier_xref_dbg AS
WITH
  -- 04-Mar-2021,R.Donakonda: created UAT test dbg view for BPU-Supplier table
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_data AS
  (
    SELECT --+ materialize
      bpu.bpu_cd, bsx.bpu_skey, bsx.supplier_id, bsx.start_dt, bsx.end_dt,
      LISTAGG(pp.ProductCD, ';') WITHIN GROUP (ORDER BY pp.ProductCD)           AS product_list
    FROM psl
    JOIN ahmadmin.psa_benefit_provision_units     bpu
      ON bpu.psuid = psl.psuid
    JOIN ahmadmin.psa_bpu_supplier_xref           bsx
      ON bsx.bpu_skey = bpu.bpu_skey
    JOIN ahmadmin.supplier                        s
      ON s.SupplierID = bsx.supplier_id
    LEFT JOIN ahmadmin.PurchasedProduct           pp
      ON pp.SupplierID = s.SupplierID
     AND NVL(pp.ProductTerminationDT, DATE '9999-12-31') > SYSDATE
    GROUP BY bpu.bpu_cd,bsx.bpu_skey, bsx.supplier_id, bsx.start_dt, bsx.end_dt
  ),
  old_data AS
  (
    SELECT --+ materialize driving_site(ps)
      ps.PlanSponsorUniqueID||'-'||csa.CtrlSuffixAcnt||'-'||scx.PlanSummaryCD   AS bpu_cd,
      scx.ControlSuffixAccountSKEY                                              AS bpu_skey,
      scx.SupplierID                                                            AS supplier_id,
      TRUNC(scx.EffectiveStartDT)                                               AS start_dt,
      NVL(TRUNC(scx.EffectiveEndDT)+1, DATE '9999-12-31')                       AS end_dt,
      LISTAGG(ProductCD, ';') WITHIN GROUP (ORDER BY ProductCD)                 AS product_list
    FROM psl
    JOIN ahmadmin.PlanSponsor@sb1                                       ps
      ON ps.PlanSponsorUniqueID = psl.psuid
    JOIN ahmadmin.PlanSponsorControlInfo@sb1                            c
      ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
    JOIN ahmadmin.ControlSuffixAccount@sb1                              csa
      ON csa.PlansponsorControlInfoSKEY = c.PlansponsorControlInfoSKEY
    JOIN ahmadmin.SupplierCSAXREF@sb1                                   scx
      ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
    LEFT JOIN ahmadmin.PurchasedProduct@sb1                             pp
      ON pp.SupplierID = scx.SupplierID
     AND NVL(pp.ProductTerminationDT, DATE '9999-12-31') > SYSDATE
    GROUP BY ps.PlanSponsorUniqueID, csa.CtrlSuffixAcnt, scx.PlanSummaryCD,scx.ControlSuffixAccountSKEY,scx.SupplierID, TRUNC(scx.EffectiveStartDT), TRUNC(scx.EffectiveEndDT) 
  )
SELECT 'PSA_BPU_SUPPLIER_XREF' AS compare, n.* FROM (SELECT * FROM new_data MINUS SELECT * FROM old_data) n
UNION ALL
SELECT 'SUPPLIERCSAXREF' AS compare, o.* FROM (SELECT * FROM old_data) o;

GRANT SELECT ON vw_psa_uat_sb1_bpu_supplier_xref_dbg TO deployer, ods_dml, ahmadmin_read;
