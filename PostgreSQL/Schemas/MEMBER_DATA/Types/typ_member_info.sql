CREATE TYPE typ_member_info AS
(
  member_id                   BIGINT,
  member_type                 CHAR(1),
  source_patient_id           VARCHAR(10),
  gender                      CHAR(1),
  race                        VARCHAR(30),
  date_of_birth               DATE,
  claims                      typ_claim[],
  lab_results                 typ_lab_result[],
  diagnoses                   typ_patient_diagnosis[],
  medical_procedures          typ_patient_medical_procedure[],
  prescriptions               typ_prescription[],
  pre_certifications          typ_pre_certification[],
  drug_usage                  typ_drug_usage[],
  hra_results                 typ_hra_survey_response[]
);

ALTER TYPE typ_member_info OWNER TO postgres;