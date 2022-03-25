with
  det as
  (
    select --+ materialize
      inst_id, sid, username, osuser, sql_id, sql_child_number,
      seconds_in_wait, event wait_event,
      --p1text||': '||p1 wait_p1, p2text||': '||p2 wait_p2, p3text||': '||p3 wait_p3,
      blocking_instance, blocking_session
    from gv$session
    where status = 'ACTIVE'
  )
  , h as
  (
    select --+ materialize
      level lvl, d.*
    from det d
    connect by nocycle inst_id = prior blocking_instance and sid = prior blocking_session
    start with d.username = 'CEAPP' and d.blocking_session is not null
     and (inst_id, sid) not in (select distinct nvl(blocking_instance, 0), nvl(blocking_session, 0) from det)
  )
select h.*, sbc.name, sbc.value_string, replace(replace(sq.sql_text,'  ',' '),'"','') sql_text
from h
left join gv$sql sq on sq.inst_id = h.inst_id and sq.sql_id = h.sql_id and sq.child_number = h.sql_child_number
left join gv$sql_bind_capture sbc on sbc.inst_id = sq.inst_id and sbc.hash_value = sq.hash_value and sbc.address = sq.address;
