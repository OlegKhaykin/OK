CREATE TYPE typ_pre_cert_procedure AS
(
  procedure_key             BIGINT,
  service_date              DATE,
  procedure_cd              VARCHAR(20),
  code_set_type             VARCHAR(10),
  primary_procedure_flag    CHAR(1),
  national_care_provider_id VARCHAR(10),
  effective_change_date     DATE
);

ALTER TYPE typ_pre_cert_procedure OWNER TO postgres;