CREATE TABLE IF NOT EXISTS reported_drug_usage
(
  member_id             BIGINT NOT NULL,
  drug_usage_key        BIGINT NOT NULL,
  fill_date             DATE NOT NULL,
  drug_cd               VARCHAR(20) NOT NULL,
  code_set_type         VARCHAR(10) NOT NULL CONSTRAINT chk_prescription_code_type CHECK(code_set_type IN ('NDC','RXNORM','OTHER')) DEFAULT 'OTHER',
  drug_name             VARCHAR(50),
  dosage                VARCHAR(30),
  num_of_days_supplied  INT,
  status                VARCHAR(255),
  change_reason         VARCHAR(255),
  non_compliant_flag    CHAR(1) NOT NULL CONSTRAINT chk_reported_drug_usage_non_complient CHECK(non_compliant_flag IN ('Y','N')) DEFAULT 'N',
  non_compliant_reason  VARCHAR(255),
  termed_flag           VARCHAR(1) NOT NULL CONSTRAINT chk_reported_drug_usage_termed CHECK(non_compliant_flag IN ('Y','N')) DEFAULT 'N',
  update_source         VARCHAR(20),
  deletion_source       VARCHAR(20),
  inserted_by           VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt           TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by            VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt            TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE reported_drug_usage OWNER TO postgres;