CREATE OR REPLACE FUNCTION tab_member_info(p_member_ids IN BIGINT[], p_begin_date IN DATE, p_end_date IN DATE)
RETURNS TABLE(member_info JSON)
LANGUAGE PLPGSQL STABLE STRICT SECURITY DEFINER SET search_path TO 'member_data' AS $$
DECLARE
  v_dummy_dt  CHAR(10);
BEGIN
  v_dummy_dt := set_config('he.begin_date', TO_CHAR(p_begin_date, 'YYYY-MM-DD'), FALSE);
  v_dummy_dt := set_config('he.end_date', TO_CHAR(p_end_date, 'YYYY-MM-DD'), FALSE);

  RETURN QUERY
  SELECT
    TO_JSON
    (
      ROW
      (
        m.member_id,
        m.member_type_cd,
        m.source_patient_id,
        m.gender,
        m.race,
        m.date_of_birth,
        ARRAY(SELECT v.claim FROM v_claims v WHERE v.member_id = m.member_id ORDER BY (v.claim).claim_key), -- Claims
        array_cat -- Lab Results
        (
          ARRAY(SELECT v.lab_result FROM v_lab_results v WHERE v.member_id = m.member_id ORDER BY (v.lab_result).result_key),
          ARRAY(SELECT v.htrack_result FROM v_htrack_results v WHERE v.member_id = m.member_id ORDER BY (v.htrack_result).result_key)
        ),
        ARRAY(SELECT v.diagnosis FROM v_patient_diagnoses v WHERE v.member_id = m.member_id ORDER BY (v.diagnosis).diagnosis_key), -- Diagnoses
        ARRAY(SELECT v.medical_procedure FROM v_patient_medical_procedures v WHERE v.member_id = m.member_id ORDER BY (v.medical_procedure).procedure_key), -- Procedures
        ARRAY(SELECT v.prescription FROM v_prescriptions v WHERE v.member_id = m.member_id ORDER BY (v.prescription).prescription_key), -- Prescriptions
        ARRAY(SELECT v.pre_certification FROM v_pre_certifications v WHERE v.member_id = m.member_id ORDER BY (v.pre_certification).case_key), -- Pre-Certifications
        ARRAY(SELECT v.drug_usage FROM v_reported_drug_usage v WHERE v.member_id = m.member_id ORDER BY (v.drug_usage).drug_usage_key), -- Reported Drug Usage
        array_cat
        (
          ARRAY(SELECT v.response FROM v_hra_survey_results v WHERE v.member_id = m.member_id ORDER BY (v.response).response_key), -- HRA Survey Results
          ARRAY(SELECT v.response FROM v_hra_htrack_results v WHERE v.member_id = m.member_id ORDER BY (v.response).response_key) -- HRA Health Tracker Results
        )
      )::typ_member_info
    )
  FROM UNNEST(p_member_ids) p
  JOIN members m ON m.member_id = p;
END;$$
