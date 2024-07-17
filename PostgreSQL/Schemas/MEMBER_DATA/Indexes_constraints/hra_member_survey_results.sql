CREATE INDEX IF NOT EXISTS ix_hra_member_survey_qa ON hra_member_survey_results(question_id, answer_id, data_source);

ALTER TABLE hra_member_survey_results ADD CONSTRAINT pk_hra_member_survey_results PRIMARY KEY (member_id, response_key);
ALTER TABLE hra_member_survey_results ADD CONSTRAINT uk_hra_member_survey_results UNIQUE (member_id, response_date, question_id, answer_id, data_source);
ALTER TABLE hra_member_survey_results ADD CONSTRAINT fk_hra_survey_results_member FOREIGN KEY(member_id) REFERENCES members(member_id);

