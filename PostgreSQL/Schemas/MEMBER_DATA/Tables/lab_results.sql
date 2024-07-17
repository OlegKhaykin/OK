CREATE TABLE IF NOT EXISTS lab_results
(
  member_id                   BIGINT NOT NULL,
  result_key                  BIGINT NOT NULL,
  service_date                DATE NOT NULL,
  loinc                       VARCHAR(10) NOT NULL,
  lab_test_name               VARCHAR(50),
  numeric_value               NUMERIC,
  min_value                   NUMERIC,
  max_value                   NUMERIC,
  text_value                  VARCHAR(200),
  unit_of_measure             VARCHAR(30),
  care_provider_npi           VARCHAR(10),
  hdms_provider_id            VARCHAR(30),
  place_of_service_cd         VARCHAR(24),
  feed_source                 VARCHAR(10),
  claim_key                   BIGINT,
  exclusion_cd                CHAR(2) NOT NULL CONSTRAINT chk_lab_result_excl CHECK(exclusion_cd IN ('IN', 'VO')),
  inserted_by                 VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt                 TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by                  VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt                  TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE lab_results OWNER to postgres;

COMMENT ON TABLE lab_results IS 'Results of Laborartory Tests conducted for Members';
