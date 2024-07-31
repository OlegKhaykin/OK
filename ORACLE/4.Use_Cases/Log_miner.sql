--==============================================================================
-- As DBA:
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
select supplemental_log_data_min from v$database; -- shoulld be 'YES' or 'IMPLICIT'

--==============================================================================
alter session set container = CDB$ROOT;
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
select * from v$containers;

select * from v$log;
select * from v$logfile;
select * from v$log_history;

select * from V$ARCHIVED_LOG where first_time > trunc(sysdate);

exec dbms_logmnr.add_logfile('C:\ORACLE\ORADATA\OKWIN\REDO01.LOG');
exec dbms_logmnr.add_logfile('C:\ORACLE\ORADATA\OKWIN\REDO02.LOG');
exec dbms_logmnr.add_logfile('C:\ORACLE\ORADATA\OKWIN\REDO03.LOG');
exec dbms_logmnr.add_logfile('C:\ORACLE\FLASH_RECOVERY_AREA\OKWIN\ARCHIVELOG\2022_09_08\O1_MF_1_174_KKLXKOQ4_.ARC');

exec dbms_logmnr.remove_logfile('C:\ORACLE\ORADATA\OKWIN\REDO03.LOG');

select * from v$logmnr_logs; -- list of the redo log files added to the log miner session

-- OPTIONS: COMMITTED_DATA_ONLY (2) + DICT_FROM_ONLINE_CATALOG (16) = 18
exec dbms_logmnr.start_logmnr(startTime => sysdate, options=>18);
exec dbms_logmnr.end_logmnr;

select * from v$logmnr_contents 
where seg_owner = 'C##OLEG';