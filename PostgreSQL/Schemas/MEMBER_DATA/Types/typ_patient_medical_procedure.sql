CREATE TYPE typ_patient_medical_procedure AS
(
  procedure_key             BIGINT,
  service_date              DATE,
  procedure_cd              VARCHAR,
  code_set_type             VARCHAR(10),
  modifier1                 VARCHAR(10),
  modifier2                 VARCHAR(10),
  modifier3                 VARCHAR(10),
  modifier4                 VARCHAR(10),
  care_provider_npi         VARCHAR(10),
  place_of_service_cd       VARCHAR(24),
  claim_key                 BIGINT,
  claim_line_no             INT
);

ALTER TYPE typ_patient_medical_procedure OWNER TO postgres;