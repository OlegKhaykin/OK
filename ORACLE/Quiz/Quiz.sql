select * from dba_registry;

--==============================================================================
-- Q1:
-- Q1-a: works fine with Oracle 19c:
with 
  graph as 
  (
    select  1 id,  2 parent_id from dual union all 
    select  1 id,  3 parent_id from dual union all 
    select  4 id,  3 parent_id from dual union all 
    select  5 id,  4 parent_id from dual union all 
    select  6 id,  5 parent_id from dual union all 
    select  7 id,  6 parent_id from dual union all 
    select  8 id,  7 parent_id from dual union all 
    select  7 id,  8 parent_id from dual union all
    select  8 id, 10 parent_id from dual union all
    select  9 id,  9 parent_id from dual union all 
    select 12 id, 11 parent_id from dual
    -- I added the following 3 edges to see how cycles are handled:
    union all
    select  10 id, 13 parent_id from dual union all
    select  13 id, 14 parent_id from dual union all
    select  14 id, 10 parent_id from dual
  ),
  norm as
  (
    select rownum rnum, id, parent_id
    from
    (
      select distinct 
        greatest(id, parent_id) parent_id,
        least(id, parent_id) id
      from graph
      where id <> parent_id -- to eliminate 9-9
    )
    order by id, parent_id
  ),
  h(rnum, lvl, id) as
  (
    select 0, 1, 1 from dual -- here the user should specify the starting node, 1 in this case
    union all
    select n.rnum, h.lvl+1, decode(n.id, h.id, n.parent_id, n.id)
    from h
    join norm n
      on (n.id = h.id or n.parent_id = h.id)
     and n.rnum <> h.rnum
  )
  cycle id set is_cycle to 'Y' default 'N'
select id from
(
  select
    h.*,
    row_number() over(partition by h.id order by h.lvl) rn
  from h
  where is_cycle = 'N'
)
where rn = 1
order by lvl, id;

-- Q1-b (PL/SQL) - to be used with older Oracle versions where CYCLE clause was not yet available:
with
  graph as 
  (
    select  1 id,  2 parent_id from dual union all 
    select  1 id,  3 parent_id from dual union all 
    select  4 id,  3 parent_id from dual union all 
    select  5 id,  4 parent_id from dual union all 
    select  6 id,  5 parent_id from dual union all 
    select  7 id,  6 parent_id from dual union all 
    select  8 id,  7 parent_id from dual union all 
    select  7 id,  8 parent_id from dual union all
    select  8 id, 10 parent_id from dual union all
    select  9 id,  9 parent_id from dual union all 
    select 12 id, 11 parent_id from dual
    -- I added the following 3 edges to see how cycles are handled:
    union all
    select  10 id, 13 parent_id from dual union all
    select  13 id, 14 parent_id from dual union all
    select  14 id, 10 parent_id from dual
  )
select column_value id
from table(pkg_graph.traverse(cursor(select * from graph), 1));

--==============================================================================
-- Q2:
alter session set nls_date_format = 'DD.MM.YYYY HH24.MI.SS';

with
  log as 
  (
    select 'U1' username, date '2013-08-08'+1/24  logon_time, date '2013-08-08'+10/24 logoff_time from dual union all
    select 'U1' username, date '2013-08-08'+6/24  logon_time, date '2013-08-08'+14/24 logoff_time from dual union all 
    select 'U1' username, date '2013-08-08'+4/24  logon_time, date '2013-08-08'+12/24 logoff_time from dual union all
    select 'U1' username, date '2013-08-08'+8/24  logon_time, date '2013-08-08'+17/24 logoff_time from dual union all
    select 'U1' username, date '2013-08-08'+16/24 logon_time, date '2013-08-08'+18/24 logoff_time from dual union all
    select 'U1' username, date '2013-08-08'+9/24  logon_time, date '2013-08-08'+16/24 logoff_time from dual union all
    select 'U2' username, date '2013-08-08'+1/24  logon_time, date '2013-08-08'+3/24  logoff_time from dual union all
    select 'U2' username, date '2013-08-08'+2/24  logon_time, date '2013-08-08'+12/24 logoff_time from dual union all
    select 'U2' username, date '2013-08-08'+11/24 logon_time, date '2013-08-08'+13/24 logoff_time from dual union all
    select 'U2' username, date '2013-08-08'+10/24 logon_time, date '2013-08-08'+14/24 logoff_time from dual
  ),
  events as
  (
    select username, tstamp, event
    from log unpivot(tstamp for event in (logon_time as 1, logoff_time as -1))
  )
select
  username,
  max(sess_cnt) cnt_sessions,
  min(tstamp) keep(dense_rank last order by sess_cnt) time
from
(
  select
    username, tstamp,
    sum(event) over(partition by username order by tstamp rows between unbounded preceding and current row) sess_cnt
  from events
)
group by username order by username;

--==============================================================================
-- Q3:
alter session set nls_timestamp_format = 'dd/mm/yyyy hh24:mi:ss.ff9';
alter session set nls_timestamp_format = 'dd/mm/yyyy hh24:mi:ss';

-- Q3-a, not so good because I selected twice from the same dataset (risk_values):
with
  risk(created, expired, value) as
  (
    select timestamp '2022-01-01 00:00:01', timestamp '2022-01-01 00:00:02', 1 from dual union all
    select timestamp '2022-01-01 00:00:01', timestamp '2022-01-01 00:00:03', 10 from dual union all
    select timestamp '2022-01-01 00:00:01', null, 100 from dual union all
    select timestamp '2022-01-01 00:00:02', null, 2000 from dual union all
    select timestamp '2022-01-01 00:00:02', timestamp '2022-01-01 00:00:03', 1000 from dual union all
    select timestamp '2022-01-01 00:00:02', timestamp '2022-01-01 00:00:04', 10000 from dual union all
    select timestamp '2022-01-01 00:00:04', null, 100000 from dual
  ),
  risk_values as
  ( -- To improve performance:
    select /*+ materialize */ * from risk
  ),
  stats as
  (
    select created as tstamp, value as created_val, to_number(null) as expired_val from risk_values
    union all
    select expired, null, value from risk_values where expired is not null
  )
select tstamp, sum(created_val) as total_created, sum(expired_val) total_expired
from stats
group by tstamp order by 1;

-- Q3-b, a better way is to unpivot/pivot requires only one scan:
with
  risk(created, expired, value) as
  (
    select timestamp '2022-01-01 00:00:01', timestamp '2022-01-01 00:00:02', 1 from dual union all
    select timestamp '2022-01-01 00:00:01', timestamp '2022-01-01 00:00:03', 10 from dual union all
    select timestamp '2022-01-01 00:00:01', null, 100 from dual union all
    select timestamp '2022-01-01 00:00:02', null, 2000 from dual union all
    select timestamp '2022-01-01 00:00:02', timestamp '2022-01-01 00:00:03', 1000 from dual union all
    select timestamp '2022-01-01 00:00:02', timestamp '2022-01-01 00:00:04', 10000 from dual union all
    select timestamp '2022-01-01 00:00:04', null, 100000 from dual
  )
select * from
(
  select tstamp, balance_type, value
  from risk unpivot(tstamp for balance_type in (created as 'C', expired AS 'E'))
)
pivot(sum(value) for balance_type in ('C' as total_created, 'E' as total_expired))
order by tstamp;

--==============================================================================
-- Q4:
with 
  master as 
  (
    select 1 as id_m, 111 as value from dual union all 
    select 2 as id_m, 222 as value from dual union all
    select 3 as id_m, 333 as value from dual union all 
    select 4 as id_m, 444 as value from dual union all 
    select 5 as id_m, 555 as value from dual union all 
    select 6 as id_m, 666 as value from dual
  ),
  detail as 
  (
    select 1 as id_m, 1 as grp from dual union all
    select 1 as id_m, 2 as grp from dual union all
    select 1 as id_m, 4 as grp from dual union all 
    select 2 as id_m, 3 as grp from dual union all
    select 2 as id_m, 4 as grp from dual union all
    select 3 as id_m, 1 as grp from dual union all
    select 3 as id_m, 3 as grp from dual union all
    select 3 as id_m, 5 as grp from dual
  ),
  det as
  (
    select
      d.grp,
      m.value,
      decode(row_number() over(partition by m.id_m order by grp), 1, m.value, 0) val
    from master m
    left join detail d on d.id_m = m.id_m
  )
--select * from det order by grp nulls first;
select
  grp,
  decode(grp, null, sum(val), sum(value)) allsum
from det
group by rollup(grp)
having grouping(grp) = 1 or grp is not null
order by grp nulls first;

--==============================================================================
-- Q5:
with
  tree as 
  (
    select 3  id, 1    parent_id, 0 sign from dual union all
    select 4  id, 2    parent_id, 0 sign from dual union all
    select 5  id, 2    parent_id, 0 sign from dual union all
    select 6  id, 3    parent_id, 0 sign from dual union all
    select 7  id, 3    parent_id, 0 sign from dual union all
    select 8  id, 3    parent_id, 0 sign from dual union all
    select 9  id, 4    parent_id, 0 sign from dual union all
    select 10 id, 4    parent_id, 1 sign from dual union all
    select 11 id, 7    parent_id, 1 sign from dual union all
    select 12 id, 7    parent_id, 0 sign from dual union all
    select 13 id, 9    parent_id, 0 sign from dual union all
    select 14 id, 9    parent_id, 1 sign from dual union all
    select 15 id, 9    parent_id, 1 sign from dual union all
    select 2  id, null parent_id, 0 sign from dual union all
    select 1  id, null parent_id, 0 sign from dual
  ),
  h as
  (
    select connect_by_root(id) signed_node, level lvl, id
    from tree
    connect by id = prior parent_id -- the only connect by
    start with sign = 1
  )
select * from
(
  select * from
  (
    select
      signed_node, id,
      max(lvl) over(partition by signed_node) - lvl as back_lvl
    from h
  )
  where back_lvl < 3
)
pivot
(
  max(id)
  for back_lvl in (0 as id_lvl1, 1 as id_lvl2, 2 as id_lvl3)
)
order by signed_node; 
