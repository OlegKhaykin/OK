SELECT SYS_CONTEXT('USERENV','INSTANCE') FROM dual;

SELECT * FROM TABLE
(
  gv$
  (
    CURSOR
    (
      SELECT
        SYS_CONTEXT('USERENV','INSTANCE') inst_id,
        module_id, originating_timestamp, message_text
      FROM v$diag_alert_ext
      WHERE originating_timestamp > SYSTIMESTAMP - INTERVAL '60' MINUTE
      -- and module_id = 'GoldenGate'
      ORDER BY originating_timestamp DESC
    )
  )
);