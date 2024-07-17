-- Table: patient_pre_auth_case
-- Table: patient_pre_auth_case

-- DROP TABLE IF EXISTS patient_pre_auth_case;

-- ------------ Write CREATE-TABLE-stage scripts -----------

CREATE TABLE IF NOT EXISTS patient_pre_auth_case(
    patient_pre_auth_case_key BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    admit_dt TIMESTAMP(0) WITHOUT TIME ZONE,
    discharge_dt TIMESTAMP(0) WITHOUT TIME ZONE,
    approved_length_of_stay BIGINT,
    primary_diagnosis_cd CHARACTER VARYING(20),
    primary_procedure_cd CHARACTER VARYING(20),
    admitting_provider_phone CHARACTER VARYING(15),
    facility_phone CHARACTER VARYING(15),
    source_record_sent_dt TIMESTAMP(0) WITHOUT TIME ZONE,
    exclusion_cd CHARACTER(2),
    inserted_dt TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL DEFAULT current_timestamp,
    inserted_by CHARACTER VARYING(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    updated_dt TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL DEFAULT current_timestamp,
    updated_by CHARACTER VARYING(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    diag_code_set_type CHARACTER VARYING(10),
    proc_code_set_type CHARACTER VARYING(10),
    CONSTRAINT xpk_patient_pre_auth_case PRIMARY KEY (patient_pre_auth_case_key)
 );
