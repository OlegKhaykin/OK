CREATE OR REPLACE VIEW v_pre_certifications(member_id, pre_certification) AS
SELECT
  -- 2022-01-12, O. Khaykin: created
  member_id,
  ROW
  (
    c.case_key, c.source_case_id, c.case_type_id, c.service_date, c.status_cd, c.effective_change_date,
    ARRAY
    (
      SELECT precert_diagnosis FROM v_pre_cert_diagnoses v
      WHERE v.member_id = c.member_id AND v.case_key = c.case_key
    ),
    ARRAY
    (
      SELECT precert_procedure FROM v_pre_cert_procedures v
      WHERE v.member_id = c.member_id AND v.case_key = c.case_key
    )
  )::typ_pre_certification
FROM pre_cert_insurance_cases c
WHERE c.exclusion_cd = 'IN'
AND c.effective_change_date BETWEEN get_begin_date() AND get_end_date();

ALTER VIEW v_pre_certifications OWNER TO postgres;