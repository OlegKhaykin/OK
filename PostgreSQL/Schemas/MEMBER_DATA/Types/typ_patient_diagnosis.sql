CREATE TYPE typ_patient_diagnosis AS
(
  diagnosis_key             BIGINT,
  service_date              DATE,
  diagnosis_cd              VARCHAR,
  code_set_type             VARCHAR(10),
  care_provider_npi         VARCHAR(10),
  place_of_service_cd       VARCHAR(24),
  claim_key                 BIGINT,
  claim_line_no             INT
);

ALTER TYPE typ_patient_diagnosis OWNER TO postgres;