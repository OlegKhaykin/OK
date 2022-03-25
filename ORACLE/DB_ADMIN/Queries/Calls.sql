alter session set current_schema = ahmadmin;

drop table tst_ok_calls purge;

create table tst_ok_calls as
with
  src as
  (
    select -- materialize
      line, text
    from dba_source
    where owner = 'AHMADMIN'
    and type = 'PACKAGE BODY'
    and name = 'PSA_DATA_INGEST'
    and text not like '%/*%'
    and text not like '%begin_action%'
    and text not like '%end_action%'
  ),
  plist as
  (
    select *
    from
    (
      select
        line begin_line,
        nvl(lead(line) over(order by line), 15001)-1 end_line, 
        upper(regexp_substr(text, '(procedure|function)', 1, 1,'i',1)) prg_type,
        upper(regexp_substr(text, '(procedure|function)\s+([[:alnum:]_]+)',1,1,'i',2)) prg_name,
        text
      from src
      where regexp_like(text, 'procedure|function', 'i') 
      and text not like '%-%'
    )
    where prg_name is not null
  ) 
--select * from plist;
  , calls as
  (
    select --+ materialize
      clr.prg_name as caller_prg_name,
      s.line,
      cld.prg_name as called_prg_name,
      s.text
    from plist                                                  clr
    join src                                                    s
      on s.line between clr.begin_line and clr.end_line
    join plist                                                  cld
      on regexp_like(s.text, cld.prg_name||'(\s|\(|$)+', 'i')
     and (cld.begin_line > s.line or cld.end_line < s.line)
  )
--select * from calls where caller_prg_name = 'spm_get_supplier_payload_AA';
  , dep as
  (
    select --+ materialize
      distinct
      caller_prg_name,
      called_prg_name
    from calls
  )
--select * from dep;
  , cnb as
  (
    select
      connect_by_root caller_prg_name           root_caller,
      sys_connect_by_path(called_prg_name,'/')  cnb_path,
      level lvl
    from dep
    connect by caller_prg_name = prior called_prg_name
    start with caller_prg_name not in (select called_prg_name from dep)
  )
  , un as
  (
    select
      root_caller||cnb_path     full_path,
      max(lvl) over(partition by root_caller) max_lvl
    from cnb
    union
    select prg_name, 0
    from plist
    where upper(prg_name) not in (select upper(caller_prg_name) from dep)
    and upper(prg_name) not in (select upper(called_prg_name) from dep)
  )
select full_path from un
order by max_lvl, lower(full_path);

select * from tst_ok_calls
--where full_path like '%SET_STG_CONTROL_STATUS%'   
order by length(full_path) desc;

/*
SPT_PROCESS_SUPPLIER/PROCESS_BPLV_DATA/SPT_CREATE_MOVE_SUPPLIER/SPT_CREATE_CSA_SUPP_BPLV/SPT_ADD_PRODUCT
SPT_PROCESS_SUPPLIER/PROCESS_BPLV_DATA/SPT_CREATE_MOVE_SUPPLIER/SPT_DERIVE_BY_BPLV_PRODUCT/SPT_ADD_PRODUCT
SPT_PROCESS_SUPPLIER/PROCESS_BPLV_DATA/SPT_CREATE_MOVE_SUPPLIER/SPT_DERIVE_BY_BPLV_PRODUCT/SPT_CREATE_CSA_SUPP_BPLV/SPT_ADD_PRODUCT
*/