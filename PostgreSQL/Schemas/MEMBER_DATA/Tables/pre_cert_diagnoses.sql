CREATE TABLE IF NOT EXISTS pre_cert_diagnoses
(
  member_id                 BIGINT NOT NULL,
  diagnosis_key             BIGINT NOT NULL,
  case_key                  BIGINT NOT NULL,
  diagnosis_cd              VARCHAR(20) NOT NULL,
  code_set_type             VARCHAR(10) NOT NULL CONSTRAINT chk_precert_diagnosis_code_system CHECK(code_set_type IN ('ICD9CM','ICD10CM','OTHER')),
  primary_diagnosis_flag    CHAR(1) NOT NULL CONSTRAINT chk_precert_primary_diagnosis CHECK(primary_diagnosis_flag IN ('Y','N')),
  service_date              DATE NOT NULL,
  care_provider_npi         VARCHAR(10),
  effective_change_date     DATE NOT NULL,
  exclusion_cd              VARCHAR(2) NOT NULL CONSTRAINT chk_precert_diagnosis_exclude CHECK(exclusion_cd IN ('IN','EX')),
  inserted_by               VARCHAR(30)NOT NULL DEFAULT SESSION_USER,
  inserted_dt               TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by                VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt                TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE pre_cert_diagnoses OWNER to postgres;

COMMENT ON COLUMN pre_cert_diagnoses.care_provider_npi IS 'National ID of the Medical Care Provider';
COMMENT ON COLUMN pre_cert_diagnoses.exclusion_cd IS 'IN - included, EX - excluded';
COMMENT ON COLUMN pre_cert_diagnoses.service_date IS 'Date when the service was rendered or the procedure was conducted';
COMMENT ON COLUMN pre_cert_diagnoses.effective_change_date IS 'Date when this information was last updated in the source system';
