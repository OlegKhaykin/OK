CREATE OR REPLACE VIEW v_pre_cert_procedures(member_id, case_key, precert_procedure) AS
SELECT
  -- 2022-01-12, O. Khaykin: created
  member_id,
  case_key,
  ROW
  (
    procedure_key,
    service_date,
    procedure_cd,
    code_set_type,
    primary_procedure_flag,
    care_provider_npi,
    effective_change_date
  )::typ_pre_cert_procedure
FROM pre_cert_medical_procedures
WHERE exclusion_cd = 'IN'
AND service_date BETWEEN get_begin_date() AND get_end_date();

ALTER VIEW v_pre_cert_procedures OWNER TO postgres;