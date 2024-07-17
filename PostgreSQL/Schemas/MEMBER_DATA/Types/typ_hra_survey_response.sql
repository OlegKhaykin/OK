CREATE TYPE typ_hra_survey_response AS
(
  response_key                BIGINT,
  response_date               DATE,
  answer_cd                   VARCHAR(30),
  response_text               VARCHAR(4000),
  data_source                 VARCHAR(20),
  feed_type                   VARCHAR(20)
);

ALTER TYPE typ_hra_survey_response OWNER TO postgres;
