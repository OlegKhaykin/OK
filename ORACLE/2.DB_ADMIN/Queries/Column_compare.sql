with
  tab_list as
  (
    SELECT 'MRDM' owner, cnf.table_name FROM cnf data_archival cnf 
  ),
  dev as
  (
    select --+ materialize
      t.table_name, c.column_id, c.column_name,
      api.get_norm_type(c.data_type) data_type 
    from tab_list t 
    join v_column_info c on c.owner = t.owner and c.table_name = t.table_name 
  ),
  qa as
  (
    select --+ materialize
      t.table_name, c.column_id, c.column_name,
      api.get_norm_type(c.data_type) data_type
    from tab_list t
    join v_column_info@qa c on c.owner = t.owner and c.table_name = t.table_name
  ),
  prod as 
  (
    select --+ materialize
      t.table_name, c.column_id, c.column_name,
      api.get_norm_type(c.data_type) data_type
    from tab_list t
    join v_column_info@prod c on c.owner = t.owner and c.table_name = t.table_name 
  ),
  tab_cols as
  (
    select table_name, column_name from dev union 
    select table_name, column_name from qa union
    select table_name, column_name from prod
  ),
  info as
  (
    select
      tc.table_name, tc.column_name,
      dev.column_id dev_col_id,   nvl(dev.data_type, 'N/A') dev_data_type,
      qa.column_id  qa_col_id,    nvl(qa.data_type, 'N/A') qa_data_type,
      prod.column_id prod_col_id, nvl(prod.data_type, 'N/A') prod data_type
    from tab_cols tc
    left join dev on dev.table_name = tc.table_name and dev.column_name = tc.column_name
    left join qa on qa.table_name = tc.table_name and qa.column_name = tc.column_name
    left join prod on prod.table_name = tc.table_name and prod.column_name = tc.column_name
  )
select * from info where dev_data_type <> qa_data_type or qa_data_type <> prod data_type; 
