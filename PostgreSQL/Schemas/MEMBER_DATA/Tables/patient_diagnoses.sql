CREATE TABLE IF NOT EXISTS patient_diagnoses
(
  member_id                 BIGINT NOT NULL,
  diagnosis_key             BIGINT NOT NULL,
  service_date              DATE NOT NULL,
  diagnosis_cd              VARCHAR(20) NOT NULL,
  code_set_type             VARCHAR(10) NOT NULL,
  care_provider_npi         VARCHAR(10),
  place_of_service_cd       VARCHAR(24),
  claim_key                 BIGINT,
  claim_line_no             BIGINT,
  hdms_provider_id          VARCHAR(30),
  exclusion_cd              VARCHAR(2) NOT NULL CONSTRAINT chk_patient_diagnosis_excl CHECK(exclusion_cd IN ('IN','VO')),
  inserted_by               VARCHAR(30) DEFAULT SESSION_USER,
  inserted_dt               TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP,
  updated_by                VARCHAR(30) DEFAULT SESSION_USER,
  updated_dt                TIMESTAMP(0) DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE patient_diagnoses OWNER to postgres;

COMMENT ON COLUMN patient_diagnoses.claim_line_no IS 'Claim line number in relation to other lines on the same Claim';
