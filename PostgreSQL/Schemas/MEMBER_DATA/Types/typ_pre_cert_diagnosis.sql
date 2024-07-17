CREATE TYPE typ_pre_cert_diagnosis AS
(
  diagnosis_key             BIGINT,
  diagnosis_cd              VARCHAR(20),
  code_set_type             VARCHAR(10),
  primary_diagnosis_flag    CHAR(1),
  service_date              DATE,
  care_provider_npi         VARCHAR(10),
  effective_change_date     DATE
);

ALTER TYPE typ_pre_cert_diagnosis OWNER TO postgres;