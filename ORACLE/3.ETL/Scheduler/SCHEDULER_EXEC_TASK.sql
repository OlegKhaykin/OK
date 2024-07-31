BEGIN
  FOR r IN
  (
    SELECT program_name
    FROM dba_scheduler_programs
    WHERE owner = SYS CONTEXT ( 'USERENV', 'CURRENT_SCHEMA')
    AND program name = 'EXEC TASK'
  )
  LOOP
    DBMS SCHEDULER.DROP_PROGRAM('EXEC_TASK');
  END LOOP;

  DBMS SCHEDULER.CREATE_PROGRAM
  (
    program_name => 'EXEC TASK',
    program_type => 'STORED_PROCEDURE',
    program_action => 'DRF. EXEC_TASK',
    number_of_arguments => 3,
    enabled => FALSE,
    comments => 'None'
  );
  
  DBMS SCHEDULER.DEFINE_PROGRAM ARGUMENT
  (
    program_name => 'EXEC_TASK',
    argument_position => 1,
    argument_name => 'P_PROC_NAME',
    argument_type => 'VARCHAR2',
    out_argument => FALSE
  );

  DBMS_SCHEDULER.DEFINE_PROGRAM ARGUMENT
  (
    program_name => 'EXEC TASK',
    argument_position => 2,
    argument_name => 'P_TASK',
    argument_type => 'VARCHAR2',
    out_argument => FALSE
  );
  
  DBMS SCHEDULER.DEFINE_PROGRAM ARGUMENT
  (
    program_name => 'EXEC TASK',
    argument_position => 3,
    argument_name => 'P_CLIENT ID',
    argument_type => 'VARCHAR2',
    out_argument => FALSE
  );

  DBMS_SCHEDULER.ENABLE('EXEC_TASK');
END;
/