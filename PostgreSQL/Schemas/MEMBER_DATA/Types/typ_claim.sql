CREATE TYPE typ_claim AS
(
  claim_key                         BIGINT,
  actual_claim_id                   VARCHAR(30),
  claim_type_cd                     VARCHAR(24),
  service_start_date                DATE,
  service_end_date                  DATE,
  principal_diagnosis_cd            VARCHAR(20),
  admitting_diagnosis_cd            VARCHAR(20),
  code_set_type                     VARCHAR(10),
  operating_provider_npi            VARCHAR(10),
  attending_provider_npi            VARCHAR(10),
  other_provider_npi                VARCHAR(10),
  facility_npi                      VARCHAR(10),
  diagnosis_related_group_cd        VARCHAR(4),
  discharge_disposition_cd          VARCHAR(24),
  received_date                     DATE,
  replaced_claim_key                BIGINT
);

ALTER TYPE typ_claim OWNER TO postgres;