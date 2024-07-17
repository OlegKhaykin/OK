-- Table: patient_pre_auth_case_hist

-- DROP TABLE IF EXISTS patient_pre_auth_case_hist;


-- ------------ Write CREATE-TABLE-stage scripts -----------

CREATE TABLE IF NOT EXISTS patient_pre_auth_case_hist(
    patient_pre_auth_case_hist_key BIGINT NOT NULL,
    patient_pre_auth_case_key BIGINT NOT NULL,
    member_id bigint NOT NULL,
    inout_patient_flg CHARACTER(1),
    inserted_dt TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL DEFAULT current_timestamp,
    inserted_by CHARACTER VARYING(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    updated_dt TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL DEFAULT current_timestamp,
    updated_by CHARACTER VARYING(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    CONSTRAINT xpk_patient_pre_auth_case_hist PRIMARY KEY (patient_pre_auth_case_hist_key)
);

-- ------------ Write CREATE-INDEX-stage scripts -----------

CREATE INDEX IF NOT EXISTS xie1_patient_pre_auth_case_hist
ON patient_pre_auth_case_hist
USING BTREE (patient_pre_auth_case_key ASC NULLS LAST, patient_pre_auth_case_hist_key ASC NULLS LAST);


-- ------------ Write CREATE-CONSTRAINT-stage scripts -----------

ALTER TABLE patient_pre_auth_case_hist
ADD CONSTRAINT patient_pre_auth_case_hist_c01 CHECK (inout_patient_flg IN ('I', 'O'));

CREATE INDEX patient_pre_auth_case_hist_idx1
    ON patient_pre_auth_case_hist USING btree
    (member_id ASC NULLS LAST)
    TABLESPACE pg_default;
