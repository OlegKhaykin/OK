CREATE OR REPLACE VIEW v_all_indexes AS
SELECT
  owner, index_name, table_owner, table_name, uniqueness,
  TO_CHAR(SUBSTR(concat_v2_set(CURSOR(
    SELECT column_name FROM all_ind_columns 
    WHERE index_owner = i.owner AND index_name = i.index_name
    ORDER BY column_position)), 1, 500)
  ) col_list
FROM all_indexes i
WHERE index_type = 'NORMAL';

GRANT READ ON v_all_indexes TO PUBLIC;