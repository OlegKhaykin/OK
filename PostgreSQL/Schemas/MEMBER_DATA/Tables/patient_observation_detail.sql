-- Table: patient_observation_detail

-- DROP TABLE IF EXISTS patient_observation_detail;

-- ------------ Write CREATE-TABLE-stage scripts -----------

CREATE TABLE IF NOT EXISTS patient_observation_detail(
    patient_observation_detail_key BIGINT NOT NULL,
    member_id bigint NOT NULL,
    patient_observation_key BIGINT NOT NULL,
    observation_detail_system_nm CHARACTER VARYING(200),
    observation_detail_cd CHARACTER VARYING(100),
    value_cd CHARACTER VARYING(100),
    numeric_low_value BIGINT,
    non_numeric_txt CHARACTER VARYING(255),
    inserted_dt TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL DEFAULT current_timestamp,
    inserted_by CHARACTER VARYING(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    updated_dt TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL DEFAULT current_timestamp,
    updated_by CHARACTER VARYING(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    CONSTRAINT xpk_patient_observation_detail PRIMARY KEY (patient_observation_detail_key)
);

-- ------------ Write CREATE-INDEX-stage scripts -----------

CREATE INDEX xie1_patient_observation_detail
ON patient_observation_detail
USING BTREE (patient_observation_key ASC NULLS LAST);

CREATE INDEX patient_observation_detail_idx2
    ON patient_observation_detail USING btree
    (member_id ASC NULLS LAST)
    TABLESPACE pg_default;