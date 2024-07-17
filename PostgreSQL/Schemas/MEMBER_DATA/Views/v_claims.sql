CREATE VIEW v_claims(member_id, claim) AS
SELECT
  member_id,
  ROW
  (
    claim_key,
    source_claim_id,
    claim_type_cd,
    service_start_date,
    service_end_date,
    principal_diagnosis_cd,
    admitting_diagnosis_cd,
    code_set_type,
    operating_provider_npi,
    attending_provider_npi,
    other_provider_npi,
    facility_npi,
    diagnosis_related_group_cd,
    discharge_disposition_cd,
    received_date,
    replaced_claim_key
  )::typ_claim
FROM patient_claims
WHERE exclusion_cd = 'IN'
AND 
(
  service_start_date BETWEEN get_begin_date() AND get_end_date()
  OR service_end_date BETWEEN get_begin_date() AND get_end_date()
);

ALTER VIEW v_claims OWNER TO postgres;