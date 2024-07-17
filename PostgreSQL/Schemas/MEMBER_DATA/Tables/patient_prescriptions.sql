CREATE TABLE IF NOT EXISTS patient_prescriptions
(
  member_id               BIGINT NOT NULL,
  prescription_key        BIGINT NOT NULL,
  service_date            DATE NOT NULL,
  drug_cd                 VARCHAR(20) NOT NULL,
  code_set_type           VARCHAR(10) NOT NULL CONSTRAINT chk_prescription_code_type CHECK(code_set_type IN ('NDC','RXNORM','OTHER')) DEFAULT 'OTHER',
  number_of_days_supplied INT,
  quantity                NUMERIC,
  care_provider_npi       VARCHAR(10),
  hdms_provider_id        VARCHAR(30),
  claim_key               BIGINT,
  place_of_service_cd     VARCHAR(24),
  exclusion_cd            VARCHAR(2) NOT NULL CONSTRAINT chk_prescription_excl CHECK (exclusion_cd IN ('IN', 'VO')),
  inserted_by             VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt             TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by              VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt              TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE patient_prescriptions OWNER TO postgres;
