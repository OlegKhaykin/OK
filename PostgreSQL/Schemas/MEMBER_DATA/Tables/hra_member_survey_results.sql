CREATE TABLE IF NOT EXISTS hra_member_survey_results
(
  member_id             BIGINT NOT NULL,
  response_key          BIGINT NOT NULL,
  question_id           BIGINT NOT NULL,
  answer_id             BIGINT NOT NULL,
  data_source           VARCHAR(20) NOT NULL,
  response_date         DATE,
  response_value        NUMERIC,
  response_text         VARCHAR(4000),
  inserted_by           VARCHAR(30)   NOT NULL DEFAULT SESSION_USER,
  inserted_dt           TIMESTAMP(0)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by            VARCHAR(30)   DEFAULT SESSION_USER,
  updated_dt            TIMESTAMP(0)  DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH(member_id);

ALTER TABLE hra_member_survey_results OWNER TO postgres;