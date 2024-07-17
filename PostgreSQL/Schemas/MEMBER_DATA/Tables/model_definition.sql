-- Table: model_definition

-- DROP TABLE model_definition;

CREATE TABLE IF NOT EXISTS model_definition
(
    model_key int not null,
    inserted_by character varying(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    inserted_dt TIMESTAMP(6) without time zone NOT NULL DEFAULT current_timestamp,
    updated_by character varying(30) COLLATE pg_catalog."default" NOT NULL DEFAULT SESSION_USER,
    updated_dt TIMESTAMP(6) without time zone NOT NULL DEFAULT current_timestamp,
    CONSTRAINT model_definition_pk PRIMARY KEY (model_key)
);

ALTER TABLE model_definition
    OWNER to postgres;
