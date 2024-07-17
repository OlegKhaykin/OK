CREATE OR REPLACE VIEW v_hra_survey_results(member_id, response) AS
SELECT
  -- 2022-01-30, O. Khaykin: created
  r.member_id,
  ROW
  (
    r.response_key,
    r.response_date,
    r.data_source||r.question_id||'.'||answer_id, -- answer_cd
    r.response_text,
    r.data_source,
   'ADMIN' -- feed_type
  )::typ_hra_survey_response
FROM hra_member_survey_results              r
WHERE r.response_date BETWEEN get_begin_date() AND get_end_date();

ALTER VIEW v_hra_survey_results OWNER TO postgres;
