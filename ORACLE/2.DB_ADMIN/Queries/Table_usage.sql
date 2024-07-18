alter session set current_schema = AHMADMIN; 
alter session set current_schema = CSID; 

select * from dba_dependencies
where referenced_owner = 'CSID' and referenced_type = 'TABLE' and referenced_name = 'MEMBERDERIVEDFACT' and type <> 'SYNONYM'; 


drop table tst_ok_table_usage purge;
 
create table csid.tst_ok_table_usage as
with
  par as
  (
    select /*+ materialize*/ *
    FROM
    (
      select 'NOBODY' owner, 'PROCEDURE' type, 'DUMMY' name, 1 first_line, 10000 last_line from dual
      --union all select 'AHMADMIN' owner, 'PROCEDURE' type, 'SP_PSALOADAHDICSAPROCESS' name, 1 begin_line, 10000 end_line from dual
      --union all SELECT 'AHMADMIN' owner, 'PACKAGE BODY' type, 'PSA_DATA_INGEST' name, 1 begin_line, 15000 end_line from dual
      --union all select 'ODS' owner, 'PACKAGE BODY' type, 'ODS_ACCOUNTSUPPLIERSYNC' name, 1 begin_line, 15000 end_line from dual
      union all select 'CSID' owner, 'PACKAGE BODY' type, 'CEPKG_OUTPUT_ALL_120' name, 1 first_line, 21000 last_line from dual
      
    )
  ),
  src as
  (
    select --+ materialize
      s.owner plsql_owner, s.type plsql_type, s.name plsql_name,
      s.line, s.text, p.last_line
    from par                                  p
    join dba_source                           s
      on s.owner = p.owner and s.type = p.type and s.name = p.name
     and s.line between p.first_line and p.last_line
    and text not like '%/*%' and text not like '%--%'
    and text not like '%begin_action%'
    and text not like '%end_action%'
    --and ltrim(text) not like '--%'
    
  )
--select * from src order by line;
  , prc_lines as
  (
    select
      plsql_owner, plsql_type, plsql_name,
      upper(regexp_substr(text, '(procedure|function)', 1, 1,'i',1))                      prg_type,
      upper(regexp_substr(text, '(procedure|function|end)\s+([[:alnum:]_]+)',1,1,'i',2))  prg_name,
      case when regexp_like(text, '(procedure|function)', 'i') then line end              begin_line,
      case when regexp_like(text, 'end', 'i') then line end                               end_line, 
      text, line, last_line
    from src
    where regexp_like(text, '^\s*(procedure|function|end)\s+([[:alnum:]_]+)', 'i')
    and not regexp_like(text, 'end\s+(if|loop|case)', 'i') 
  )
--select * from prc_lines order by nvl(begin_line, end_line);
  , prg_list as
  (
    select
      plsql_owner, plsql_type, plsql_name,
      min(prg_type)                                                           prg_type,
      prg_name,
      min(begin_line)                                                         begin_line,
      min(end_line)                                                           end_line
    from
      prc_lines
/*    (
      select
        plsql_owner, plsql_type, plsql_name, prg_type,
        nvl(prg_name, lag(prg_name) over(order by line))                        prg_name,
        begin_line,
        coalesce(end_line, lead(begin_line) over(order by line)-1, last_line)   end_line,
        line
      from prc_lines
    )*/
    group by plsql_owner, plsql_type, plsql_name, prg_name
  )
--select * from prg_list where prg_type is not null order by begin_line;
  , prc as
  (
    select
      c.plsql_owner, c.plsql_type, c.plsql_name, c.prg_type,
      nvl2(p.prg_name, p.prg_name||'.', null)||c.prg_name prg_name,
      c.begin_line, c.end_line
    from prg_list c
    left join prg_list p
      on p.plsql_owner = c.plsql_owner and p.plsql_type = c.plsql_type and p.plsql_name = c.plsql_name and p.begin_line < c.begin_line and p.end_line > c.end_line
    where c.prg_type is not null
  )
--select * from prc order by plsql_owner, plsql_name, begin_line;    
  , tab as
  (
    select --+ materialize
      d.owner             as plsql_owner,
      d.type              as plsql_type,
      d.name              as plsql_name,
      d.referenced_owner  as table_owner,
      d.referenced_type   as table_type,
      d.referenced_name   as table_name
    from par                                                          p
    join dba_dependencies                                             d
      on d.owner = p.owner and d.type = p.type and d.name = p.name
     and d.referenced_type in ('TABLE', 'VIEW')
  )
--select * from tab;
  , sql_lines as
  (
    select --+ materialize
      s.plsql_owner, s.plsql_type, s.plsql_name,
      s.line, s.text,
      case 
        when upper(s.text) like '%INSERT%' then 'INSERT'
        when upper(s.text) like '%UPDATE%' then 'UPDATE'
        when upper(s.text) like '%DELETE%' then 'DELETE'
        when upper(s.text) like '%MERGE%'  then 'MERGE'
        when upper(s.text) like '%TRUNCATE%' then 'TRUNCATE'
      end dml_operation,
      case when regexp_like(s.text, '\s(INSERT|UPDATE|DELETE|MERGE|TRUNCATE)\s', 'i') then s.line end dml_line, 
      t.table_owner,
      t.table_name,
      nvl2(t.table_name, s.line, null)  table_line
    from src s
    left join tab t
      on t.plsql_owner = s.plsql_owner and t.plsql_type = s.plsql_type and t.plsql_name = s.plsql_name
     and regexp_like(upper(s.text), '(\.|\s|^)'||t.table_name||'(''|\s|$)') 
    where regexp_like(s.text, '\s(INSERT|UPDATE|DELETE|MERGE|TRUNCATE)\s', 'i')
    or t.table_name is not null
  )
--select * from sql_lines;  
  , sq as
  (
    select
      plsql_owner, plsql_type, plsql_name, text,
      case when dml_line < table_line-1 then table_line else dml_line end sql_line,
      case when dml_line < table_line-1 then 'SELECT' else dml_operation end sql_operation,
      table_owner, table_name, table_line
    from
    (
      select
        plsql_owner, plsql_type, plsql_name, text,
        nvl(nvl(dml_line, lag(dml_line) over(partition by plsql_name order by line)), 0) dml_line,  
        nvl(dml_operation, lag(dml_operation) over(partition by plsql_name order by line)) dml_operation,
        table_owner, table_name, table_line
      from sql_lines
    )
    where table_name is not null
  )
--select * from sq where sql_operation <> 'SELECT';   
  , sql_info as
  (
    select
      sq.plsql_owner, sq.plsql_name, prc.prg_type, prc.prg_name, prc.begin_line, prc.end_line,
      sq.sql_line, sq.sql_operation, sq.table_owner, sq.table_name,
      rank() over(partition by sq.plsql_owner, sq.plsql_type, sq.plsql_name, sq.sql_line order by prc.begin_line desc) rnk
    from sq
    left join prc
      on prc.plsql_owner = sq.plsql_owner and prc.plsql_type = sq.plsql_type and prc.plsql_name = sq.plsql_name
     and prc.begin_line <= sq.sql_line and prc.end_line >= sq.sql_line
  )
select plsql_owner, plsql_name, prg_type, prg_name, begin_line, end_line, sql_line, sql_operation, table_owner, table_name, rnk 
from sql_info
--where rnk = 1
;

--==============================================================================
-- Overall table usage stats:
with
  det as
  (
    select
      table_owner, table_name, plsql_owner, plsql_name, 
      prg_name, begin_line, end_line,  
      listagg(substr(sql_operation, 1, 1), ',') within group
      (
        order by decode(substr(sql_operation, 1, 1), 'S', 1, 'I', 2, 'M', 3, 'U', 4, 5)
      ) usage 
    from
    (
      select distinct
        plsql_owner, plsql_name, prg_name, begin_line, end_line,
        table_owner, table_name, sql_operation
      from tst_ok_table_usage
      where 1=1
      --and sql_operation <> 'SELECT'
    )
    group by plsql_owner, plsql_name, prg_name, begin_line, end_line, table_owner, table_name
  )
select prg_name, table_owner, table_name, usage 
from det /*where table_name in ('MEMBERHEALTHSTASSIGNEDPROVIDER','MEMBERHEALTHSTATEPROVIDER')*/
where 1=1
and prg_name in ('OUTPUTWRAPPER','OUTPUTWRAPPER_HEALTHENGINERUN'/*,'OUTPUTWRAPPER_HEALTHENGINERUNRETRO'*/)
order by table_owner, table_name;
select distinct table_name from det where prg_name in ('OUTPUTWRAPPER','OUTPUTWRAPPER_HEALTHENGINERUN','OUTPUTWRAPPER_HEALTHENGINERUNRETRO') order by case when table_name like '%RETRO%' then 2 else 1 end, table_name;
--select distinct prg_name, begin_line from det where table_name like '%ARCH' order by begin_line;
select * from
(
  select table_name, prg_name, usage
  from det
  where 1=1
  and prg_name = 'OUTPUTWRAPPER_OLD'
  --where prg_name in ('OUTPUTWRAPPER','PERSONRUNOUTPUTWRAPPER','OUTPUTWRAPPER_UNIVERSALRUN','OUTPUTWRAPPER_HEALTHENGINERUN','OUTPUTWRAPPER_HEALTHENGINERUNRETRO')
)
pivot 
(
  max(usage)
  for prg_name in ('OUTPUTWRAPPER_OLD')
  --for prg_name in ('OUTPUTWRAPPER','PERSONRUNOUTPUTWRAPPER','OUTPUTWRAPPER_UNIVERSALRUN','OUTPUTWRAPPER_HEALTHENGINERUN','OUTPUTWRAPPER_HEALTHENGINERUNRETRO')
);

-- Detail table usage info:
select
  tu.prg_name, tu.begin_line, tu.end_line, tu.sql_line, tu.sql_operation, tu.table_owner, tu.table_name
from csid.tst_ok_table_usage              tu
join dba_tables                           dt
  on dt.owner = tu.table_owner
 and dt.table_name = tu.table_name
where dt.temporary = 'N'
--and tu.prg_name like 'OUTPUTWRAPPER_HEALTHENGINERUNRETRO%'
and tu.table_name in ('MEMBERDERIVEDFACT')
--and tu.sql_operation <> 'SELECT'
order by plsql_name, sql_line; 

select count(1) from csid.tst_ok_table_usage;

select * from dba_source where owner = 'CSID' and text like '%MEMBERRECOMMENDLABRESULT%';