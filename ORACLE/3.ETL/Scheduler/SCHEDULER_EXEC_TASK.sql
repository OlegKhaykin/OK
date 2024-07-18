BEGIN
  FOR r IN
  (
    SELECT program_name
    FROM dba_scheduler_programs
    WHERE owner = SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
    AND program_name = 'EXEC_TASK'
  )
  LOOP
    DBMS_SCHEDULER.DROP_PROGRAM('EXEC_TASK');
  END LOOP;
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_PROGRAM
  (
    program_name => 'EXEC_TASK',
    program_type => 'STORED_PROCEDURE',
    program_action => 'DRF.EXEC_TASK',
    number_of_arguments => 2,
    enabled => FALSE,
    comments => 'None'
  );

  DBMS_SCHEDULER.DEFINE_PROGRAM_ARGUMENT
  (
    program_name => 'EXEC_TASK',
    argument_position => 1,
    argument_name => 'P_JOB_NAME',
    argument_type => 'VARCHAR2',
    out_argument => FALSE
  );

  DBMS_SCHEDULER.DEFINE_PROGRAM_ARGUMENT
  (
    program_name => 'EXEC_TASK',
    argument_position => 2,
    argument_name => 'P_TASK',
    argument_type => 'VARCHAR2',
    out_argument => FALSE
  );

  DBMS_SCHEDULER.ENABLE('EXEC_TASK');
end;
/
