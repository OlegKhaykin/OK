with
  det as
  (
    SELECT --+ MATERIALIZE
      owner, table_name, column_id, lower(column_name) column_name,
      CASE
        WHEN data_type IN ('CHAR', 'VARCHAR2', 'RAW', 'NCHAR', 'NVARCHAR2') THEN data_type||'('||char_length||' '||DECODE(char_used, 'B', 'BYTE', 'C', 'CHAR')||')'
        WHEN data_type = 'NUMBER' AND data_precision IS NULL AND data_scale IS NULL THEN 'NUMBER'
        WHEN data_type = 'NUMBER' AND data_precision IS NULL AND data_scale = 0 THEN 'INTEGER'
        WHEN data_type = 'NUMBER' AND data_scale = 0 THEN 'NUMBER('||data_precision||')'
        WHEN data_type = 'NUMBER' THEN 'NUMBER('||data_precision||','||data_scale||')'
        ELSE data_type
      END || DECODE(nullable, 'N', ' NOT NULL') ora_data_type,
      CASE
        WHEN column_name = 'YEARQTR' THEN 'INT' 
        WHEN REGEXP_LIKE(column_name, '(ID|SKEY)$') THEN 'BIGINT' 
        WHEN data_type IN ('CHAR', 'VARCHAR2', 'RAW', 'NCHAR', 'NVARCHAR2') THEN TRANSLATE(data_type, '.N2', '.')||'('||char_length||' '||DECODE(char_used, 'B', 'BYTE', 'C', 'CHAR')||')'
        WHEN data_type = 'NUMBER' AND data_precision IS NULL AND data_scale IS NULL THEN 'NUMERIC'
        WHEN data_type = 'NUMBER' AND data_precision IS NULL AND data_scale = 0 THEN 'BIGINT'
        WHEN data_type = 'NUMBER' AND data_scale = 0 THEN 'NUMERIC('||data_precision||')'
        WHEN data_type = 'NUMBER' THEN 'NUMERIC('||data_precision||','||data_scale||')'
        ELSE data_type
      END || DECODE(nullable, 'N', ' NOT NULL') pg_data_type
    FROM dba_tab_columns
    WHERE 1=1
    and column_name = 'MEDICALPROCEDURECODE'
    --and owner not like 'A%' and owner not like '%STAG%'
    AND owner in
    (
      'dummy-1',
      --'CSID',
      'ODS',
      --'CE','AHMADMIN','ETLADMIN',
      'dummy-2'
    )
    and table_name like '%HEADER%'
/*    and table_name in
    (
      'dummy-1',
      --'MEMBERHEALTHSTATE',
      --'MEMBERHEALTHSTATE_CURR',
      'PATIENTCLAIMHEADER',
      --'MEMBERHEALTHSTATE_HIST',
      --'MEMBERHEALTHSTATE_RETRO_CURR',
      --'MEMBERHEALTHSTATE_RETRO_HIST',
      --'PATIENTMEDICALDIAGNOSIS',
      'dummy-2'
    )*/
  )
select owner, table_name, column_id, column_name, ora_data_type, pg_data_type from det order by owner, table_name, column_id;
  , ur as
  (
    select
      substr(table_name, -4) data_set,
      column_id, column_name, data_type, nullable 
    from det where table_name not like '%RETRO%'
  )
  , retro as
  (
    select
      substr(table_name, -4) data_set,
      column_id, column_name, data_type, nullable 
    from det where table_name like '%RETRO%'
  )
select
  nvl(ur.data_set, retro.data_set) "Data Set",
  nvl(ur.column_id, retro.column_id) "Column ID",
  ur.column_name ur_column_name, ur.data_type ur_data_type, ur.nullable,
  retro.column_name ret_column_name, retro.data_type ret_data_type, retro.nullable ret_nulable,
  case when retro.column_name = ur.column_name and retro.data_type = ur.data_type and retro.nullable = ur.nullable then 'Y' else 'N' end match
from ur
full join retro on retro.data_set = ur.data_set and retro.column_id = ur.column_id
order by "Data Set", "Column ID";  
