CREATE TYPE typ_prescription AS
(
  prescription_key          BIGINT,
  service_date              DATE,
  drug_cd                   VARCHAR(20),
  code_set_type             VARCHAR(10),
  number_of_days_supplieed  INT,
  drug_quantity             NUMERIC,
  care_provider_npi         VARCHAR(10),
  hdms_provider_id          VARCHAR(30),
  place_of_service_cd       VARCHAR(24),
  claim_key                 BIGINT,
  source_claim_id           VARCHAR(30)
);

ALTER TYPE typ_prescription OWNER TO postgres;