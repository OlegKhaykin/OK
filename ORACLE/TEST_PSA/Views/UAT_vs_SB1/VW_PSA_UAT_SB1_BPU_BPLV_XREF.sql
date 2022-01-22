CREATE OR REPLACE VIEW vw_psa_uat_sb1_bpu_bplv_xref AS
WITH
  -- 12-Apr-2021, OK: combined adjacent/overlapping legacy rows into one.
  -- 04-Dec-2020, O.Khaykin: created.
  psl as
  (
    SELECT /*+ materialize*/ psuid
    FROM vw_psa_plan_sponsor_list
  ),
  new_data AS
  (
    SELECT --+ materialize
      bpu.bpu_cd,
      bplv.benefitinfocd||'-'||bplv.provisioncd||'-'||bplv.linevaluecd AS bplv_cd,
      bbx.start_dt, bbx.end_dt
    FROM psl
    JOIN ahmadmin.psa_benefit_provision_units     bpu
      ON bpu.psuid = psl.psuid
    JOIN ahmadmin.psa_bpu_bplv_xref               bbx
      ON bbx.bpu_skey = bpu.bpu_skey
    JOIN ahmadmin.benefitprovisionlinevalue       bplv
      ON bplv.BenefitProvLineValID = bbx.bplv_id
  ),
  old_data AS
  (
    SELECT --+ materialize
      bpu_cd, bplv_cd, start_dt, end_dt
    FROM
    (
      SELECT
        bpu_cd, bplv_cd, end_dt,
        CONNECT_BY_ROOT start_dt  AS start_dt,
        CONNECT_BY_ISLEAF         AS is_leaf
      FROM
      (
        SELECT
          s.*,
          LAG(end_dt) OVER(PARTITION BY bpu_cd, bplv_cd ORDER BY start_dt, end_dt)    AS prev_end_dt,
          ROW_NUMBER() OVER(PARTITION BY bpu_cd, bplv_cd ORDER BY start_dt, end_dt)   AS rnum 
        FROM
        (
          SELECT --+ driving_site(ps)
            ps.plansponsoruniqueid||'-'||csa.CtrlSuffixAcnt||'-'||cbx.plansummarycd   AS bpu_cd,
            bplv.benefitinfocd||'-'||bplv.provisioncd||'-'||bplv.linevaluecd          AS bplv_cd, 
            TRUNC(cbx.BPLVStartDT)                                                    AS start_dt,
            NVL(TRUNC(cbx.BPLVEndDT)+1, DATE '9999-12-31')                            AS end_dt
          FROM psl
          JOIN ahmadmin.PlanSponsor@sb1                                         ps
            ON ps.PlanSponsorUniqueID = psl.psuid
          JOIN ahmadmin.PlanSponsorControlInfo@sb1                              c
            ON c.PlanSponsorSKEY = ps.PlanSponsorSKEY
          JOIN ahmadmin.ControlSuffixAccount@sb1                                csa
            ON csa.PlansponsorControlInfoSKEY = c.PlansponsorControlInfoSKEY
          JOIN ahmadmin.SupplierCSAXREF@sb1                                     scx
            ON scx.ControlSuffixAccountSKEY = csa.ControlSuffixAccountSKEY
          JOIN ahmadmin.CSABPLVXREF@sb1                                         cbx
            ON cbx.ControlSuffixAccountSKEY = scx.ControlSuffixAccountSKEY
           AND cbx.PlanSummaryCD = scx.PlanSummaryCD
           AND cbx.EffectiveStartDT = scx.EffectiveStartDT
          JOIN ahmadmin.BenefitProvisionLineValue@sb1                           bplv
            ON bplv.BenefitProvLineValID = cbx.BenefitProvLineValID
        ) s
      )
      CONNECT BY bpu_cd = PRIOR bpu_cd AND bplv_cd = PRIOR bplv_cd AND rnum = PRIOR rnum + 1 AND start_dt <= PRIOR end_dt 
      START WITH prev_end_dt IS NULL OR prev_end_dt < start_dt
    )
    WHERE is_leaf = 1
  )
SELECT 'PSA_BPU_BPLV_XREF minus CSABPLVXREF' AS compare, nmo.*
FROM (SELECT * FROM new_data MINUS SELECT * FROM old_data) nmo
UNION ALL
SELECT 'CSABPLVXREF minus PSA_BPU_BPLV_XREF' AS compare, omn.*
FROM (SELECT * FROM old_data MINUS SELECT * FROM new_data) omn;

GRANT SELECT ON vw_psa_uat_sb1_bpu_bplv_xref TO deployer, ods_dml, ahmadmin_read;
