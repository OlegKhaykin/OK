alter session set current_schema = ahmadmin;

EXEC db_admin.kill_session(2857,38057);

exec xl.close_log('Cancelled');

update debuger.dbg_process_logs set result = 'Cancelled', end_time = systimestamp 
where result is null
and start_time < trunc(sysdate)
;

commit;

select max(proc_id) from debuger.dbg_process_logs where proc_id > 1800000;

with
  det as
  (
    select -- parallel(8)
      proc_id, name, comment_txt, result, start_time, end_time,
      case when days > 1 then days||' days ' when days > 0 then '1 day ' end ||
      case when days > 0 or hours > 0 then hours || ' hr ' end ||
      case when days > 0 or hours > 0 or minutes > 0 then minutes || ' min ' end ||
      round(seconds, 3)|| ' sec' time_spent
    from
    (
      select
        proc_id, name, comment_txt, result, start_time, end_time,
        extract(day from diff) days,
        extract(hour from diff) hours,
        extract(minute from diff) minutes,
        extract(second from diff) seconds
      from
      (
        select
          l.*, nvl(end_time, systimestamp) - start_time diff 
        from debuger.dbg_process_logs l
        where 1=1
        --and proc_id > 1903921
        --AND proc_id IN (/*115801,115800,*/115799)
        and name not like 'PKG_PRODUCT_SETUP_AUTOMATION%'
        --and name = 'SET_MHS_CURR_NEW_COLS'
        --and name like '%SET_MHS_CURR_%'
        --and comment_txt like '%RETRO'
        --and (result is null or result <> 'Successfully completed')
        --and start_time > sysdate - 7 --date '2020-12-20'
        --AND END_TIME is null
        --AND (result IS NULL OR result LIKE '%ORA%')
      )
    )
  )
select rownum rnum, q.* from (select det.* from det order by proc_id desc) q;
select count(1) cnt from det;

--=========================== DETAILS ==========================================
with
  det as
  (
    select
      proc_id,
      tstamp, pls_unit, 
      log_depth, action,
      --comment_txt result
      to_char(substr(comment_txt,1,4000)) result
      --,lag(to_char(substr(comment_txt,1,4000))) over(partition by proc_id, log_depth, action order by tstamp) prev_result
      --,tstamp - lag(tstamp) over(partition by proc_id, log_depth, action order by tstamp) time_spent
    from debuger.dbg_log_data
    where 1=1
    and proc_id = 1903837
    --and proc_id in (select proc_id from debuger.dbg_process_logs where proc_id >= 1903832 and comment_txt like '%artitioning%')
    and
    (
      --1=0 and   -- nothing
      1=1 or  -- everything
      action in
      (
        'Dummy',
        'Processing Partition'
      )
      or comment_txt like '%ORA-%'
    )
    and log_depth < 8
  )
select proc_id, tstamp, pls_unit, log_depth, action, result from det order by tstamp desc;   

--========================== PERFORMANCE =======================================
with
  det as
  (
    select
      proc_id, action, cnt, round(seconds, 3) sec,
      round(seconds/cnt, 6) sec_per_run
    from debuger.dbg_performance_data 
    where proc_id = 1903940
  )
--select * from det order by sec desc, proc_id;
select action, sum(cnt) cnt, sum(sec) sec from det group by action order by sec desc;

--========================== SUPPLEMENTAL ======================================
select
  dsd.proc_id, dsd.name, dsd.tstamp, dsd.value.GetTypeName(),
  t.*
from dbg_supplemental_data dsd
cross join table(get_tab_test_val(dsd.value)) t;

--========================== SETTINGS ======================================
merge into debuger.dbg_settings tgt
using
(
  select 'PSA_DATA_INGEST.SPM_GET_SUPPLIER_DETAILS' proc_name, 5 log_level from dual union all 
  select 'PKG_PRODUCT_SETUP_AUTOMATION.ARCHIVE_PERS_DATA', 5 from dual union all
  select 'PKG_PRODUCT_SETUP_AUTOMATION.PROCESS_PERS_DATA', 5 from dual union all  
  select 'PSA_DATA_INGEST.REGISTER_SEGM_CHANGE_REQ' proc_name, 5 log_level from dual union all 
  select 'PSA_DATA_INGEST.SPT_PROCESS_SUPPLIER', 5 from dual union all 
  select 'PSA_DATA_INGEST.SPM_GET_SUPPLIER_PAYLOAD_AA', 5 from dual union all 
  select 'PSA_DATA_INGEST.SPM_GET_SUPPLIERBUNDLEDETAILS', 5 from dual union all 
  select 'PSA_REGRESSION_TEST.RUN_ONE', 5 from dual union all
  select 'PURGE_PLAN_SPONSOR_DATA', 5 from dual union all
  select 'CEPKG_OUTPUT_ALL_120.OutputWrapper_HealthEngineRun', 10 from dual union all 
  select 'CEPKG_OUTPUT_ALL_120.OutputWrapper_HealthEngineRunRetro', 10 from dual 
) src
on (tgt.proc_name = src.proc_name)
when matched then update set tgt.log_level = src.log_level where tgt.log_level <> src.log_level
when not matched then insert values(src.proc_name, src.log_level);  

commit;

select * from debuger.dbg_settings order by 1;

insert into debuger.dbg_settings values('PKG_DB_MAINTENANCE_API.DROP_PARTITIONS', 10);

insert into debuger.dbg_settings values('DEALLOCATE_UNUSED_SPACE', 10);
insert into debuger.dbg_settings values('PKG_DB_MAINTENANCE_API.DROP PARTITIONS', 10);
