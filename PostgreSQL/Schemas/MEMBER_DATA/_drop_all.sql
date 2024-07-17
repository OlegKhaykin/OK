set schema 'member_data';

DROP FUNCTION IF EXISTS tab_member_info;

\ir Views/_drop_views.sql
\ir Types/_drop_types.sql
\ir Tables/_drop_tables.sql

DROP FUNCTION IF EXISTS get_begin_date;
DROP FUNCTION IF EXISTS get_end_date;

set schema 'member_data_nopart';
\ir Tables/_drop_tables.sql
