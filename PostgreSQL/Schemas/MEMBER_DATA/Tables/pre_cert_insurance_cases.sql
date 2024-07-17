CREATE TABLE IF NOT EXISTS pre_cert_insurance_cases
(
  member_id             BIGINT NOT NULL,
  case_key              BIGINT NOT NULL,
  source_case_id        VARCHAR(25) NOT NULL,
  case_type_id          INT NOT NULL CONSTRAINT chk_pre_cert_case_type CHECK (case_type_id IN (1, 2)),
  effective_change_date DATE NOT NULL,
  status_cd             VARCHAR(20) NOT NULL CONSTRAINT chk_pre_cert_case_status CHECK (status_cd IN ('DISSTAT_A','DISSTAT_E','DISSTAT_T')),
  service_date          DATE NOT NULL,
  received_date         DATE,
  exclusion_cd          CHAR(2) CONSTRAINT chk_pre_cert_case_excl CHECK(exclusion_cd IN ('IN', 'VO')),
  inserted_by           VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt           TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by            VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt            TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
)
PARTITION BY HASH(member_id);

ALTER TABLE pre_cert_insurance_cases OWNER to postgres;

COMMENT ON COLUMN pre_cert_insurance_cases.case_key  IS 'Surrogate key - to be used for justifications';
COMMENT ON COLUMN pre_cert_insurance_cases.source_case_id  IS 'ID of Insurance Case in the source system';
COMMENT ON COLUMN pre_cert_insurance_cases.effective_change_date IS 'Date when information about this Insurance Case was last updated in the source system';
COMMENT ON COLUMN pre_cert_insurance_cases.case_type_id  IS '1 - short-term disability, 2 - long-term disability';
COMMENT ON COLUMN pre_cert_insurance_cases.status_cd  IS 'DISSTAT_A - Active, DISSTAT_E - Expired, DISSTAT_T - Terminated';
COMMENT ON COLUMN pre_cert_insurance_cases.service_date  IS '???';
COMMENT ON COLUMN pre_cert_insurance_cases.received_date  IS '???';
