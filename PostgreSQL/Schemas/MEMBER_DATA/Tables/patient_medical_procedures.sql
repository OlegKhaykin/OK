CREATE TABLE IF NOT EXISTS patient_medical_procedures
(
  member_id                 BIGINT NOT NULL,
  procedure_key             BIGINT NOT NULL,
  service_date              DATE NOT NULL,
  procedure_cd              VARCHAR(20) NOT NULL,
  code_set_type             VARCHAR(10) NOT NULL CONSTRAINT chk_patient_medproc_code_type CHECK(code_set_type IN ('ICD9CM','ICD10PCS','CPT','HCPCS','REVENUE','SNOMED','OTHER')),
  modifier1                 VARCHAR(10),
  modifier2                 VARCHAR(10),
  modifier3                 VARCHAR(10),
  modifier4                 VARCHAR(10),
  care_provider_npi         VARCHAR(10),
  claim_key                 BIGINT,
  claim_line_no             INT,
  place_of_service_cd       VARCHAR(24),
  exclusion_cd              VARCHAR(2) NOT NULL CONSTRAINT chk_patient_medproc_excl CHECK(exclusion_cd IN ('IN','VO')),
  inserted_by               VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt               TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by                VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt                TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE patient_medical_procedures OWNER TO postgres;

COMMENT ON TABLE patient_medical_procedures IS 'Medical Procedures performed on Members';
