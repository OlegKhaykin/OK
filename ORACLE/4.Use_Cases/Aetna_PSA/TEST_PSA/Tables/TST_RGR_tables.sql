/*
begin
  for r in
  (
    select table_name
    from dba_tables
    where owner = SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
    and table_name like 'TST_RGR%'
  )
  loop
    execute immediate 'drop table '||r.table_name||' purge';
  end loop;
end;
*/

declare
  v_sql varchar2(255);
begin
  for r in
  (
    select
      s.*,
      NVL2(i.table_name, 'Y', 'N') index_exists
    from
    (
      select
        lst.schema, lst.table_name, lst.tst_table_name, t.owner,
        'IX_'||lst.table_name||'_PROC_ID' index_name,
        NVL2(t.table_name, 'Y', 'N') table_exists
      from
      (
        SELECT 'AHMADMIN' schema,  'SUPPLIER' table_name,     'TST_RGR_SUPP' tst_table_name     FROM dual UNION ALL
        SELECT 'AHMADMIN',  'PURCHASEDPRODUCT',               'TST_RGR_PURCHASED_PRODUCT'       FROM dual UNION ALL
        SELECT 'AHMADMIN',  'PLANSPONSOR',                    'TST_RGR_PLAN_SPONSOR'            FROM dual UNION ALL
        SELECT 'AHMADMIN',  'PSA_CONTROLS',                   'TST_RGR_PSA_CONTROLS'            FROM dual UNION ALL
        SELECT 'AHMADMIN',  'PSA_BENEFIT_PROVISION_UNITS',    'TST_RGR_PSA_BPU'                 FROM dual UNION ALL
        SELECT 'AHMADMIN',  'PSA_BPU_BPLV_XREF',              'TST_RGR_PSA_BPU_BPLV_XREF'       FROM dual UNION ALL
        SELECT 'AHMADMIN',  'PSA_BPU_SUPPLIER_XREF',          'TST_RGR_PSA_BPU_SUPPLIER_XREF'   FROM dual UNION ALL
        SELECT 'AHMADMIN',  'VW_PSA_BPU_PRODUCT_LISTS',       'TST_RGR_PSA_BPU_EVOLUTION'       FROM dual
      ) lst
      left join dba_tables                                      t
        on t.table_name = lst.tst_table_name
       and t.owner = SYS_CONTEXT('USERENV','CURRENT_SCHEMA')
    ) s
    left join dba_indexes                                       i
      on i.table_owner = s.owner
     and i.table_name = s.tst_table_name
     and i.index_name = s.index_name
  )
  loop
    if r.table_exists = 'N' then
      v_sql := 'create table '||r.tst_table_name||
      ' as select cast(1 as integer) proc_id, t.* from '||r.schema||'.'||r.table_name||' t where rownum < 1';
      
      execute immediate v_sql;
    end if;
    
    if r.index_exists = 'N' then
      v_sql := 'create index '||r.index_name||' on '||r.tst_table_name||'(proc_id) tablespace users';

      execute immediate v_sql;
    end if;
    
    execute immediate 'grant select on '||r.tst_table_name||' to public';
  end loop;
end;
/ 
