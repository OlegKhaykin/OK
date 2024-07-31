audit connect; -- Start standard auditing of connects:
select * from dba_audit_trail; -- See standard auditing trail

select * from v$option
where parameter = 'Unified Auditing';

select * from v$parameter
where name = 'audit_trail';

select component, count(1) cnt
from auditable_system_actions
group by component;

select * from auditable_system_actions
--where component='Standard'
where upper(name) like '%SESSION%'
order by name;