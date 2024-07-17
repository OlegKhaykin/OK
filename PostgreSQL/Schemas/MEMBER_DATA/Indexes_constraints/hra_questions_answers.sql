CREATE INDEX IF NOT EXISTS ix_hra_questions_answers ON hra_questions_answers((question_id||'.'||answer_id), begin_date);

CREATE OR REPLACE FUNCTION check_hra_qa_range() RETURNS TRIGGER AS $$
DECLARE
  n_cnt INT;
BEGIN
  SELECT COUNT(1) INTO n_cnt
  FROM hra_questions_answers a
  JOIN hra_questions_answers b
    ON b.question_id = a.question_id
   AND b.answer_id = a.answer_id
   AND b.data_source = a.data_source
   AND b.begin_date < a.end_date AND b.end_date > a.begin_date
   AND a.ctid <> b.ctid;
   
  IF n_cnt > 0 THEN
    RAISE EXCEPTION 'There are % "overlaping" HRA_QUESTIONS_ANSWERS rows as the result of your change', n_cnt;
  END IF;
 
  RETURN new;
END;
$$ LANGUAGE PLpgSQL;

CREATE CONSTRAINT TRIGGER aiu_hra_questions_answers
AFTER INSERT OR UPDATE ON hra_questions_answers
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE check_hra_qa_range();
