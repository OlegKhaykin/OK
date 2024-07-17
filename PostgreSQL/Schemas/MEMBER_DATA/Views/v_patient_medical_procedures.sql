CREATE OR REPLACE VIEW v_patient_medical_procedures(member_id, medical_procedure) AS
SELECT
  -- 2022-01-13, O. Khaykin: created
  member_id,
  ROW
  (
    procedure_key,
    service_date,
    procedure_cd,
    code_set_type,
    modifier1,
    modifier2,
    modifier3,
    modifier4,
    care_provider_npi,
    place_of_service_cd,
    claim_key,
    claim_line_no
  )::typ_patient_medical_procedure
FROM patient_medical_procedures
WHERE service_date BETWEEN get_begin_date() AND get_end_date()
AND UPPER(exclusion_cd) = 'IN';

ALTER VIEW v_patient_medical_procedures OWNER TO postgres;