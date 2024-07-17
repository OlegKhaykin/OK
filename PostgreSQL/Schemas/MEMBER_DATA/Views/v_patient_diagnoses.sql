CREATE OR REPLACE VIEW v_patient_diagnoses(member_id, diagnosis) AS
SELECT
  -- 2022-01-16, O. Khaykin: created
  member_id,
  ROW
  (
    diagnosis_key,
    service_date,
    diagnosis_cd,
    code_set_type,
    care_provider_npi,
    place_of_service_cd,
    claim_key,
    claim_line_no
  )::typ_patient_diagnosis
FROM patient_diagnoses
WHERE service_date BETWEEN get_begin_date() AND get_end_date()
AND UPPER(exclusion_cd) = 'IN';