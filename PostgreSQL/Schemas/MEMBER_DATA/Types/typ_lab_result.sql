CREATE TYPE typ_lab_result AS
(
  result_key                  BIGINT,
  service_date                DATE,
  loinc                       VARCHAR(10),
  code_set_type               VARCHAR(10),
  numeric_value               NUMERIC,
  min_value                   NUMERIC,
  max_value                   NUMERIC,
  unit_of_measure             VARCHAR(30),
  care_provider_npi           BIGINT,
  hdms_provider_id            VARCHAR(30),
  claim_key                   BIGINT,
  place_of_service_cd         VARCHAR(24),
  feed_source                 VARCHAR(20)
);

ALTER TYPE typ_lab_result OWNER TO postgres;