ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS';

SELECT
  SYSTIMESTAMP,
  SCN_TO_TIMESTAMP(current_scn) current_db_timestamp
FROM v$database;

SELECT * FROM v$dataguard_stats;

SELECT * FROM v$database;

SELECT * FROM v$parameter WHERE name LIKE 'log_archive_dest%';
