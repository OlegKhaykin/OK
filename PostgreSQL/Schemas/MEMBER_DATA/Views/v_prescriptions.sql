CREATE OR REPLACE VIEW v_prescriptions(member_id, prescription) AS
SELECT
  -- 2022-01-22, O. Khaykin: created
  p.member_id,
  ROW
  (
    p.prescription_key,
    p.service_date,
    p.drug_cd,
    p.code_set_type,
    p.quantity,
    p.number_of_days_supplied,
    p.care_provider_npi,
    p.hdms_provider_id,
    p.place_of_service_cd,
    p.claim_key,
    c.source_claim_id
  )::typ_prescription
FROM patient_prescriptions        p
LEFT JOIN patient_claims          c
  ON c.member_id = p.member_id
 AND c.claim_key = p.claim_key
WHERE p.service_date BETWEEN get_begin_date() AND get_end_date() AND p.exclusion_cd = 'IN';

ALTER VIEW v_prescriptions OWNER TO postgres;