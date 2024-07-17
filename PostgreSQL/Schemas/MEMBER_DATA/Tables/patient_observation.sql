-- Table: patient_observation_detail

-- DROP TABLE IF EXISTS patient_observation_detail;

-- ------------ Write CREATE-TABLE-stage scripts -----------

CREATE TABLE IF NOT EXISTS patient_observation(
    patient_observation_key BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    observation_type_system_oid CHARACTER VARYING(64),
    exclusion_cd CHARACTER(2),
    inserted_dt TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL DEFAULT current_timestamp,
    inserted_by CHARACTER VARYING(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    updated_dt TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL DEFAULT current_timestamp,
    updated_by CHARACTER VARYING(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    CONSTRAINT xpk_patient_observation PRIMARY KEY (patient_observation_key)
);

-- ------------ Write CREATE-INDEX-stage scripts -----------

CREATE INDEX IF NOT EXISTS xie1_patient_observation
ON patient_observation
USING BTREE (member_id ASC NULLS LAST);
