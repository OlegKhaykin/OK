CREATE TABLE IF NOT EXISTS loinc
(
  loinc             VARCHAR(10)   CONSTRAINT pk_loinc PRIMARY KEY,
  code_system_name  VARCHAR(20)   NOT NULL,
  type_id           INT           NOT NULL,
  class_cd          VARCHAR(30)   NOT NULL,
  component         VARCHAR(200)  NOT NULL,
  system            VARCHAR(50),
  property          VARCHAR(10),
  unit              VARCHAR(50),
  description       VARCHAR(255),
  inserted_by       VARCHAR(30)   NOT NULL DEFAULT SESSION_USER,
  inserted_dt       TIMESTAMP(0)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by        VARCHAR(30)   NOT NULL DEFAULT SESSION_USER,
  updated_dt        TIMESTAMP(0)  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE loinc OWNER to postgres;
