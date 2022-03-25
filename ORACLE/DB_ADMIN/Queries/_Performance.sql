exec db_admin.kill_session(2717,57757);

-- Current session state and stats:
with
  sess as
  (
    select
      s.audsid, s.inst_id, s.sid, s.serial#, p.pid, p.spid, s.session_edition_id,
      --decode(s.ownerid, 2147483644, null, trunc(s.ownerid/65536)) parallel_coord_id,
      --decode(s.ownerid, 2147483644, null, mod(s.ownerid,65536)) parent_sess_sid,
      s.username, s.osuser,
      s.program, s.module, s.action, s.status,
      s.sql_id, s.sql_child_number,
      (select listagg(sql_text) within group(order by piece) from gv$sqltext where inst_id = s.inst_id and sql_id = s.sql_id) sql_text,
      s.blocking_instance, s.blocking_session
    from gv$session s
    join gv$process p on p.inst_id = s.inst_id and p.addr = s.paddr
    left join gv$sql sq on sq.inst_id = s.inst_id and sq.sql_id = s.sql_id and sq.child_number = s.sql_child_number
    where 1=1
    and s.status IN ('ACTIVE','KILLED')
    --and s.audsid = 1043681662
    --and s.osuser = 'OKhaykin'
    --and upper(sql_text) like '%MEMBERPDCSCOREHIST%'
    and s.username = 'N384433'
    --and s.module = 'MEMBERDERIVEDFACT_UR_220123'
    --and s.sid = 2061
    --and s.audsid = 618435790
    --and upper(s.program) ='SQLPLUS.EXE'
    --and s.sql_id = '3paf8n00dyqvr'
  ),
  longops as
  (
    select
      s.audsid, s.sid, s.sql_text, lo.start_time,
      lo.elapsed_seconds, lo.time_remaining, lo.message,
      lo.sql_id, lo.sql_exec_id
    from sess s
    join gv$session_longops lo
      on lo.inst_id = s.inst_id and lo.sid = s.sid and lo.serial# = s.serial#
  ),
  waits as
  (
    select
      --s.*,
      s.audsid, s.inst_id, s.sid,
      w.seq#, w.event, w.wait_class, w.state, w.wait_time_micro/1000000 wait_seconds, w.time_since_last_wait_micro/1000000 seconds_since_last_wait,
      w.p1text, p1, w.p2text, p2, w.p3text, p3
    from sess s
    join gv$session_wait w on w.inst_id = s.inst_id and w.sid = s.sid
  ),
  events as
  (
    select
      s.audsid, s.inst_id, s.sid,
      se.event, se.time_waited_micro/1000000 waited_seconds
    from sess s
    join gv$session_event se on se.inst_id = s.inst_id and se.sid = s.sid
  ),
  stats as
  (
    select
      --s.*,
      s.audsid, s.inst_id, s.sid,
      sn.name, ss.value
    from sess s
    join gv$sesstat ss
      on ss.inst_id = s.inst_id and ss.sid = s.sid and value > 0
    join gv$statname sn
      on sn.inst_id = s.inst_id and sn.statistic# = ss.statistic#
  ),
  hist as
  (
    select
      --s.*,
      s.audsid, s.inst_id, s.sid,
      ash.event,
      rank() over(partition by s.audsid, s.inst_id, s.sid order by sample_time desc) rnk
    from sess s
    join gv$active_session_history ash
      on ash.inst_id = s.inst_id and ash.session_id = s.sid and ash.session_serial# = s.serial#
  )
select audsid, program, status, 'exec db_admin.kill_session('||sid||','||serial#||');' from sess; 
select /*+ noparallel */ * from sess order by audsid, sid;
--select * from waits order by audsid, wait_seconds desc;
select * from longops where time_remaining > 0 order by audsid, start_time desc, time_remaining desc, elapsed_seconds desc;
--select * from stats order by audsid;
select * from events order by audsid;
select * from hist where rnk=1 order by audsid;

select * from table(dbms_xplan.display_cursor(sql_id => '9hr22b850678j', format => 'ALL'));

-- Active session history:
select
  sample_id, sample_time, session_id, session_serial#, sql_id, sql_plan_operation, 
  event, p1text, p1, p2text, p2, p3text, p3, wait_class, wait_time, session_state, program,
  current_obj#, --current_file#, current_block#,
  delta_time, delta_read_io_bytes
from
(
  select t.*, row_number() over(partition by session_id order by sample_id) rnum
  from gv$active_session_history t
  where sql_id='3paf8n00dyqvr' and sample_time>sysdate-1/2400
)
where rnum = 1
order by session_id;

-- ===========================  SQL execution statistics  ==============================
-- For each SQL statement currently in SGA:
select
--  a.address, c.parent_handle
  a.*, c.* 
from gv$sqlarea     a
left join gv$sql_cursor  c
  on c.parent_handle = a.address and c.inst_id = a.inst_id
where 1=1
--and a.parsing_schema_name = 'POC' and a.module = 'SQL*Plus'
--and a.sql_id = 'bz3wgf0189a4h'
and upper(a.sql_text) like '%FROM patientmedicalprocedure%'
;

select * from gv$session where sql_id = 'frzbwrc0qwj78';

-- For each plan:
select * from gv$sqlarea_plan_hash;

-- For each step of the plan:
select * from gv$sql_plan_statistics;

-- For each child cursor:
select * from gv$sql_cursor;

-- For each execution (SQL_ID + SQL_EXEC_START or SQL_EXEC_ID):
select * from gv$sql_monitor;

--================================= Execution plans ====================================
-- For the last EXPLAIN PLAN:
explain plan for
SELECT PS.MEMBERID FROM AHMMRNBUSINESSSUPPLIER BS 
JOIN CAREENGINEMEMBERPROCESSSTATUS PS ON PS.MEMBERID = BS.AHMMRNMEMBERID WHERE BS.LASTBUSINESSAHMSUPPLIERID =12906 ;

select plan_table_output from table(dbms_xplan.display);

-- For the cursor that is still in SGA:
select * from table
(
  dbms_xplan.display_cursor
  (
    sql_id =>
      'gghbyydza9mk9',
    cursor_child_no => 0,
    format => 'ALL'
  )
);

--==============================================================================
--
select * from dba_hist_sqltext where sql_text like '%FROM patientmedicalprocedure%';

-- Plan captured in AWR:
select * from table(dbms_xplan.display_awr('...'));

--==============================================================================
-- See if AWR is available:
select * from
(
  select inst_id, name, value 
  from gv$parameter where name in 
  (
    'control_management_pack_access', -- should be DIAGNOSTIC+TUNING
    'statistics_level'                -- should be TYPICAL or ALL
  )
) pivot(max(value) for inst_id in (1/*,2,3,4,5,6,7,8*/))
order by 1;

-- See available AWR snapshots:
select * from dba_hist_ash_snapshot order by 1 desc;

-- Get AWR report:
-- In theory, you can do this:
select dbms_workload_repository.awr_report_text(4251913509, 1, 993, 994, 8) from dual;
-- But better use the following scripts located in $ORACLE_HOME/rdbms/admin:
-- awrrpt.sql   - for the local database 
-- awrrpti.sql  - for specific instance

--------------------------------------------------------------------------------
-- ADDM:
-- Need ADVISOR privilege to run ADDM:
select * from user_sys_privs where privilege = 'ADVISOR';

-- To run ADDM manually in the database mode:
declare
  task varchar2(30) := 'ADDM for snapshots 993-994';
begin
  dbms_addm.analyze_db(task, 993, 994);
end;
/
-- See ADDM report:
select dbms_addm.get_report('ADDM for snapshots 993-994') from dual;

-- Create a performace baseline - a difference between 2 AWR snapshots:
begin
  dbms_workload_repository.create_baseline
  (
    start_snap_id => 979,
    end_snap_id   => 980,
    baseline_name => 'peak baseline'
    --,dbid          => 3310949047, -- NULL by default - i.e. the current database
    --,expiration    => 30
  );
end;
/


