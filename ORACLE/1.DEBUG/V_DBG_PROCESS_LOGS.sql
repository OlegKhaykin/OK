CREATE OR REPLACE VIEW v_dbg_process_logs AS
SELECT
/*
  04-OCT-2022, O. Khaykin - created.
*/
  proc_id, name, comment_txt, start_time, end_time, result,
  CASE
    WHEN days > 1 THEN days| |' days '
    WHEN days > 0 THEN days| |' day '
  END ||
  CASE WHEN days > 0 OR hrs > 0 THEN hrs||' hr ' END ||
  CASE WHEN days > 0 OR hrs > 0 OR mins > 0 THEN mins ||' min ' END ||
  LTRIM(TO_CHAR(sec, '90.00')) || ' sec' time_spent
FROM
(
  SELECT
    q.* ,
    EXTRACT (DAY FROM time_spent)     days,
    EXTRACT (HOUR FROM time_spent)    hrs,
    EXTRACT (MINUTE FROM time_spent)  mins,
    EXTRACT (SECOND FROM time_spent)  sec
  FROM
  (
    SELECT
      pl.* , NVL(end_time, systimestamp) - start_time time_spent
    FROM dbg_process_logs pl
  ) q
);

GRANT READ ON v_dbg_process_logs TO PUBLIC;
CREATE OR REPLACE PUBLIC SYNONYM v_dbg_process_logs FOR v_dbg_process_logs;