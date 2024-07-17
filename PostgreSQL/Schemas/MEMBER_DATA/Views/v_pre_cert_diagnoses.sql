CREATE OR REPLACE VIEW v_pre_cert_diagnoses(member_id, case_key, precert_diagnosis) AS
SELECT
  -- 2022-01-12, O. Khaykin: created
  member_id,
  case_key,
  ROW
  (
    diagnosis_key,
    diagnosis_cd,
    code_set_type,
    primary_diagnosis_flag,
    service_date,
    care_provider_npi,
    effective_change_date
  )::typ_pre_cert_diagnosis
FROM pre_cert_diagnoses d
WHERE exclusion_cd = 'IN'
AND service_date BETWEEN get_begin_date() AND get_end_date();

ALTER VIEW v_pre_cert_diagnoses OWNER TO postgres;