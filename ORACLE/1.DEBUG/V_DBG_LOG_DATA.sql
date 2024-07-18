CREATE OR REPLACE VIEW v_dbg_log_data AS
SELECT
/*
  04-OCT-2022, O. Khaykin - created
*/
  proc_id, tstamp, log_depth, module, action, comment_txt,
  CASE WHEN (rev_ord = 1 OR rnum = 0) AND days > 0 THEN days | | CASE WHEN days > 1 THEN ' days ' ELSE ' day ' END END ||
  CASE WHEN (rev_ord = 1 OR rnum = 0) AND (days > 0 OR hrs > 0) THEN hrs| |' hr ' END ||
  CASE WHEN (rev_ord = 1 OR rnum = 0) AND (days > 0 OR hrs > 0 OR mins > 0) THEN mins ||' min ' END ||
  CASE WHEN (rev_ord = 1 OR rnum = 0) THEN LTRIM(TO_CHAR(sec, '90.00')) || ' sec' END time_spent
FROM
(
  SELECT
    q .* ,
    EXTRACT (DAY    FROM CASE rnum WHEN 0 THEN (tstamp - prev_ts) ELSE (sys_ts - tstamp) END) days,
    EXTRACT (HOUR   FROM CASE rnum WHEN 0 THEN (tstamp - prev_ts) ELSE (sys_ts - tstamp) END) hrs,
    EXTRACT (MINUTE FROM CASE rnum WHEN 0 THEN (tstamp - prev_ts) ELSE (sys_ts - tstamp) END) mins,
    EXTRACT (SECOND FROM CASE rnum WHEN 0 THEN (tstamp - prev_ts) ELSE (sys_ts - tstamp) END) sec
  FROM
  (
    SELECT
      ld .* ,
      CAST(SYSTIMESTAMP AS TIMESTAMP)                                                                 sys_ts,
      MOD(ROW_NUMBER() OVER(PARTITION BY proc_id, log_depth ORDER BY tstamp), 2)                      rnum,
      ROW_NUMBER() OVER(PARTITION BY proc_id, log_depth ORDER BY tstamp DESC)                         rev_ord,
      LAG(tstamp) OVER(PARTITION BY proc_id, log_depth ORDER BY tstamp)                               prev_ts,
      LAG(TO_CHAR(SUBSTR(comment_txt, 1, 256))) OVER(PARTITION BY proc_id, log_depth ORDER BY tstamp) prev_comment
    FROM dbg_log_data ld
  ) q
);

GRANT READ ON v_dbg_log_data TO PUBLIC;
CREATE OR REPLACE PUBLIC SYNONYM v_dbg_log_data FOR v_dbg_log_data;