CREATE OR REPLACE VIEW v_lab_results(member_id, lab_result) AS
SELECT
  -- 2021-12-29, O. Khaykin: created
  member_id,
  ROW
  (
    result_key,
    service_date,
    loinc,
    'LOINC',
    numeric_value,
    min_value,
    max_value,
    unit_of_measure,
    care_provider_npi,
    hdms_provider_id,
    claim_key,
    place_of_service_cd,
    'ADMIN'
  )::typ_lab_result
FROM lab_results
WHERE exclusion_cd = 'IN'
AND service_date BETWEEN get_begin_date() AND get_end_date();

ALTER VIEW v_lab_results OWNER TO postgres;
