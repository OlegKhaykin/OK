CREATE TABLE IF NOT EXISTS hra_questions_answers
(
  question_id         BIGINT NOT NULL,
  answer_id           BIGINT NOT NULL,
  data_source         VARCHAR(20) NOT NULL,
  question_text       VARCHAR(4000),
  answer_text         VARCHAR(4000),
  begin_date          DATE NOT NULL,
  end_date            DATE NOT NULL DEFAULT DATE '9999-12-31',
  inserted_by         VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  inserted_dt         TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by          VARCHAR(30) NOT NULL DEFAULT SESSION_USER,
  updated_dt          TIMESTAMP(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_hra_questions_answers PRIMARY KEY(question_id, answer_id, begin_date),
  CONSTRAINT chk_hra_qa_dates CHECK(begin_date <= end_date)
);

ALTER TABLE hra_questions_answers OWNER TO postgres;

COMMENT ON COLUMN hra_questions_answers.begin_date IS 'Start of the date period when this data was, is or will be actual, inclusive. Row is logically deleted if END_DATE = START_DATE.';
COMMENT ON COLUMN hra_questions_answers.end_date IS 'End of the date period when this data was, is or will be actual, exclusive. Row is logically deleted if END_DATE = START_DATE.';
