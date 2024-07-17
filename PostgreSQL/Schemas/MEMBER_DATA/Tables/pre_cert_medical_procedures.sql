CREATE TABLE IF NOT EXISTS pre_cert_medical_procedures
(
  member_id                   BIGINT NOT NULL,
  procedure_key               BIGINT NOT NULL,
  case_key                    BIGINT NOT NULL,
  procedure_cd                VARCHAR(20) NOT NULL,
  code_set_type               VARCHAR(10) NOT NULL,
  primary_procedure_flag      CHAR(1) NOT NULL CONSTRAINT chk_precert_medproc_primary CHECK(primary_procedure_flag IN ('Y','N')),
  service_date                DATE NOT NULL,
  care_provider_npi           VARCHAR(10),
  effective_change_date       DATE NOT NULL,
  exclusion_cd                VARCHAR(2) NOT NULL CONSTRAINT chk_precert_medproc_excl CHECK(exclusion_cd IN ('IN','EX','VO')),
  inserted_by                 VARCHAR(30)NOT NULL DEFAULT SESSION_USER,
  inserted_dt                 TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by                  VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt                  TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE pre_cert_medical_procedures OWNER to postgres;

COMMENT ON COLUMN pre_cert_medical_procedures.procedure_cd IS 'Medical Procedure Code - from one of the commonly used classifiers';
COMMENT ON COLUMN pre_cert_medical_procedures.code_set_type IS 'The classifier that contains this Medical Procedure Code';
COMMENT ON COLUMN pre_cert_medical_procedures.service_date IS 'Date when this Procedure is scheduled to be performed';
COMMENT ON COLUMN pre_cert_medical_procedures.care_provider_npi IS 'National ID of the Medical Care Provider who is designated to perform this Procedure';
COMMENT ON COLUMN pre_cert_medical_procedures.exclusion_cd IS 'IN - included, EX - excluded, VO - voided';
COMMENT ON COLUMN pre_cert_medical_procedures.effective_change_date IS 'Date when this information was last updated in the source system';