CREATE TYPE typ_pre_certification AS
(
  case_key                  BIGINT,
  source_case_id            VARCHAR(25),
  case_type_id              INT,
  service_date              DATE,
  status_cd                 VARCHAR(20),
  effective_change_date     DATE,
  precert_diagnoses         typ_pre_cert_diagnosis[],
  precert_procedures         typ_pre_cert_procedure[]
);

ALTER TYPE typ_pre_certification OWNER TO postgres;