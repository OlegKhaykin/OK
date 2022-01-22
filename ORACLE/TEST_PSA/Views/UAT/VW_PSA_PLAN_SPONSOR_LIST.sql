CREATE OR REPLACE VIEW vw_psa_plan_sponsor_list AS
WITH
  -- 06-Jan-2021, O.Khaykin: created
  par AS
  (
    SELECT --+ materialize
      COLUMN_VALUE AS psuid
    FROM TABLE(ods.split_string(psa.get_parameter('PSUID')))
  )
SELECT
  NVL(stg.psuid, ps.psuid)      AS psuid,
  psa.set_today(TRUNC(SYSDATE)) AS today,
  stg.file_dt                   AS file_dt
FROM
(
  SELECT DISTINCT
    TO_DATE(REGEXP_SUBSTR(b.FileNM, '(20\d{6}).*\.txt$', 1, 1, NULL, 1), 'YYYYMMDD') AS file_dt,
    sc.psuid
  FROM ods.SupplierBatch                            b
  JOIN ods.stg_SupplierControl                      sc
    ON sc.SupplierBatchSkey = b.SupplierBatchSkey
  LEFT JOIN par
    ON par.psuid = sc.psuid
  WHERE b.SupplierBatchSkey = TO_NUMBER(psa.get_parameter('BATCH_SKEY'))
  AND sc.psuid = NVL2(psa.get_parameter('PSUID'), par.psuid, sc.psuid)
) stg
FULL JOIN
(
  SELECT ps.PlanSponsorUniqueID AS psuid
  FROM ahmadmin.PlanSponsor ps
  LEFT JOIN par
    ON par.psuid = ps.PlanSponsorUniqueID
  WHERE psa.get_parameter('BATCH_SKEY') IS NULL
  AND ps.PlanSponsorUniqueID = CASE
    WHEN psa.get_parameter('PSUID') IS NULL THEN ps.PlanSponsorUniqueID
    ELSE par.psuid
  END
) ps
ON ps.psuid = stg.psuid;