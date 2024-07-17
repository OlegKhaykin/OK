CREATE OR REPLACE VIEW v_hra_htrack_results(member_id, response) AS
SELECT
  -- 2022-01-30, O. Khaykin: created
  r.member_id,
  ROW
  (
    r.result_key, -- response_key
    r.measurement_date, -- response_date
    qa.data_source||e.medical_procedure_cd, -- answer_cd
    CASE t.non_numeric_flag WHEN 'N' THEN r.numeric_value::VARCHAR ELSE r.text_value END, -- response_text
    qa.data_source, -- Note: in the legacy Oracle code, this value is hard-coded: 'DEVICE'
   'DEVICE' -- feed_type
  )::typ_hra_survey_response
FROM htrack_results                         r
JOIN health_tracker_elements                e
  ON e.element_key = r.element_key
JOIN hra_questions_answers                  qa
  ON qa.question_id||'.'||qa.answer_id = e.medical_procedure_cd
 AND qa.begin_date <= r.measurement_date AND qa.end_date > r.measurement_date
 AND qa.data_source = 'PHR'
JOIN htrack_measurement_types               t
  ON t.measurement_key = r.measurement_key
WHERE r.measurement_date BETWEEN get_begin_date() AND get_end_date();

ALTER VIEW v_hra_htrack_results OWNER TO postgres;
