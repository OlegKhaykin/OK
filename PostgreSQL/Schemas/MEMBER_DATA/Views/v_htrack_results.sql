CREATE OR REPLACE VIEW v_htrack_results(member_id, htrack_result) AS
SELECT
  -- 2021-12-28, O. Khaykin: created
  r.member_id,
  ROW
  (
    r.result_key,
    r.measurement_date,
    e.loinc,
    l.code_system_name,
    r.numeric_value,
    xr.range_min_value,
    xr.range_max_value,
    mt.unit_of_measure,
    NULL, -- care_provider_npi
    NULL, -- hdms_provider_referebce_id,
    NULL, -- claim_key
    NULL, -- place_of_service_cd
   'DEVICE' -- feed_source
  )::typ_lab_result
FROM htrack_results                             r
JOIN htrack_element_measurement_xref            xr
  ON xr.element_key = r.element_key
 AND xr.measurement_key = r.measurement_key
JOIN htrack_measurement_types                   mt
  ON mt.measurement_key = xr.measurement_key
JOIN health_tracker_elements                    e
  ON e.element_key = xr.element_key
JOIN loinc                                      l
  ON l.loinc = e.loinc -- this join is not supported by FK
WHERE r.measurement_date BETWEEN get_begin_date() AND get_end_date();

ALTER VIEW v_htrack_results OWNER TO postgres;