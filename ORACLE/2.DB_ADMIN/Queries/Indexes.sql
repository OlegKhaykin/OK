alter session set current_schema = ahmadmin; 

WITH
  col_list AS
  (
    SELECT --+ materialize
      COLUMN_VALUE column_name
    FROM TABLE(tab_v256
    (
      'INSERTDT', 'INSERT_DT', 'INSERTEDDT', 'INSERTED_DT', 'RECORDINSERTDT', 'RECORDINSERTDATE', 
      'UPDATEDT', 'UPDATEDDT', 'RECORDUPDTDT', 'RECORDUPDATEDATE',
      'LAST_INS_UPD_TS','LAST_DML_DT','VALID_FROM_DT'
    ))
  ),
  tab_list AS
  (
    SELECT  --+ materialize
      COLUMN_VALUE table_name
    FROM TABLE(tab_v256
    (
      'ASSIGNEDADMINUSER', 'ASSIGNEDTASK', 'CEINSTRUCTIONS', 'CEMESSAGINGSETTINGS', 
      'CESETTINGS', 'CONTROLSUFFIXACCOUNT', 'CSABPLVXREF', 'DMSETTINGS',
      'FAMILYSUPPLIERXREF', 'HIST_CONTROL_SEGMENT_CHANGES', 'MAHSETTINGS', 
      'MEMBERDIRECTEDWELLNESSSETTINGS', 'PLANSPONSOR', 'PLANSPONSORCONTROLINFO',
      'PSA_SEGMENT_CHANGE_REQUESTS',  'PURCHASEDPRODOFFNGATTRVALXREF', 
      'PURCHASEDPRODOFFNGEXTVENDOR', 'PURCHASEDPRODOFFNGMAXREWARD', 
      'PURCHASEDPRODSETTNGATTRVALXREF', 'PURCHASEDPRODUCT',
      'PURCHASEDPRODUCTCOMMSETUP', 'PURCHASEDPRODUCTINSTRUCTIONS',
      'PURCHASEDPRODUCTOFFERING', 'PURCHASEDPRODUCTSETTINGS',
      'PURCHASEDPRODUCTTARGETPLN', 'PURCHASEDPRODUCTTHERAPEUTICCLS',
      'SUPPLIER', 'SUPPLIERACCTPACKAGEXREF', 'SUPPLIERCSAXREF', 
      'SUPPLIERGROUP', 'SUPPLIERORGRELATION', 'UMPRODUCTSETTINGS', 
      'VBFSETTINGS', 'WORKFLOWPROCESSINSTANCE' 
    ))
  )
  , tcol as
  (
    select --+ materialize
      t.owner, t.table_name, tc.column_name 
    from tab_list tl
    join dba_tables t
      on t.table_name = tl.table_name
     and t.owner in ('AHMADMIN','ODS')
    join dba_tab_columns tc
      on tc.owner = t.owner
     and tc.table_name = t.table_name
    join col_list cl
      on cl.column_name = tc.column_name
  )
--select * from tcol;
  , icol as
  (
    select i.table_owner, i.table_name, i.index_name, ic.column_name
    from tab_list                                                     tl
    join dba_indexes                                                  i
      on i.table_name = tl.table_name
     and i.table_owner in ('AHMADMIN','ODS')
    join dba_ind_columns                                              ic
      on ic.index_owner = i.owner
     and ic.index_name = i.index_name
    join col_list                                                     cl
      on cl.column_name = ic.column_name
  )
--select * from icol;
  , det as
  (
    select
      tcol.*, icol.index_name,
      'IX_'||
      replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(tcol.table_name,
      'SUPPLIER', 'SUPP'), 'WORKFLOWPROCESSINSTANCE', 'WF'), 'ORGANIZATION', 'ORG'), 'RELATIONSHIP', 'REL'), 'PURCHASED', 'P'),'PRODUCT','PRD'),
      'INSURANCE', 'INS'), 'WELLNESS', 'WLNS'), 'MEMBER', 'MMBR'), 'SETTINGS', 'SET'), 'RELATION', 'REL'), 'PLANSPONSOR', 'PSPNSR'),
      'SEGMENT', 'SEG'), 'REQUESTS', 'REQ'), 'SETTNG', 'SET'
      ) ||
      '_'||case when tcol.column_name like '%UPD%' then 'UPDTS' else 'INSTS' end new_idx_name
    from tcol
    left join icol
      on icol.table_name = tcol.table_name
     and icol.table_owner = tcol.owner
     and icol.column_name = tcol.column_name
    where index_name is null
  )
select
  length(new_idx_name) len, owner, table_name,
  'CREATE INDEX '||owner||'.'||new_idx_name||' ON '||owner||'.'||table_name||'('||column_name||') PARALLEL 32;
ALTER INDEX '||new_idx_name||' NOPARALLEL;' cmd
from det
--WHERE LENGTH(new_idx_name) > 30
;
