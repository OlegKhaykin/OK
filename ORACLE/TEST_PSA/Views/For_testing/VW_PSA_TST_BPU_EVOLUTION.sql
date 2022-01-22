CREATE OR REPLACE VIEW test_psa.vw_psa_tst_bpu_evolution AS
WITH
  -- 29-Jul-2021, OK: moved to TEST_PSA.
  dt AS
  (
    SELECT
      bpu_skey, start_dt,
      LEAD(start_dt) OVER(PARTITION BY bpu_skey ORDER BY start_dt) end_dt 
    FROM
    (
      SELECT bpu_skey, start_dt FROM ahmadmin.tmp_psa_bpu_products
      UNION
      SELECT bpu_skey, end_dt FROM ahmadmin.tmp_psa_bpu_products
    )
  )
SELECT
  xl.get_current_proc_id                                      AS proc_id,
  psuid, bpu_skey, start_dt, end_dt,
  LISTAGG(product_cd, ';') WITHIN GROUP (ORDER BY product_cd) AS product_list,
  COUNT(1)                                                    AS product_cnt,
  MAX(inserted_ts)                                            AS inserted_ts
FROM
(
  SELECT
    bp.psuid, dt.bpu_skey, dt.start_dt, dt.end_dt,
    bp.product_cd || CASE WHEN bp.product_cd IN ('MAH', 'AHYW') THEN '_'||bp.variation END AS product_cd,
    MAX(inserted_ts)    AS inserted_ts
  FROM dt
  JOIN ahmadmin.tmp_psa_bpu_products bp
    ON bp.bpu_skey = dt.bpu_skey
   AND bp.start_dt <= dt.start_dt AND bp.end_dt >= dt.end_dt
  WHERE dt.end_dt IS NOT NULL AND dt.end_dt > dt.start_dt
  GROUP BY
   bp.psuid, dt.bpu_skey, dt.start_dt, dt.end_dt,
   bp.product_cd || CASE WHEN bp.product_cd IN ('MAH', 'AHYW') THEN '_'||bp.variation END
)
GROUP BY psuid, bpu_skey, start_dt, end_dt;

GRANT SELECT ON vw_psa_tst_bpu_evolution TO PUBLIC;