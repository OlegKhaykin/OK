\set ON_ERROR_STOP on
\set QUIET on

\echo Deploying Health Engine back-end software ...

CREATE SCHEMA IF NOT EXISTS member_data_nopart;
SET SCHEMA 'member_data_nopart';

\echo
\echo Releases/2022/member_data_tables.sql ...
\i Releases/2022/member_data_tables.sql

\echo
\echo Releases/2022/member_data_indexes_constraints.sql ...
\i Releases/2022/member_data_indexes_constraints.sql

CREATE SCHEMA IF NOT EXISTS member_data;
SET SCHEMA 'member_data';

\echo Schemas/MEMBER_DATA/Functions/get_begin_date.sql ...
\i Schemas/MEMBER_DATA/Functions/get_begin_date.sql
\echo Schemas/MEMBER_DATA/Functions/get_end_date.sql ...
\i Schemas/MEMBER_DATA/Functions/get_end_date.sql

\echo
\echo Releases/2022/member_data_tables.sql ...
\i Releases/2022/member_data_tables.sql

\echo
\echo Releases/2022/member_data_partitions.sql ...
\i Releases/2022/member_data_partitions.sql

\echo
\echo Releases/2022/member_data_types.sql ...
\i Releases/2022/member_data_types.sql

\echo
\echo Releases/2022/member_data_views.sql ...
\i Releases/2022/member_data_views.sql

\echo
\echo Schemas/MEMBER_DATA/Functions/tab_member_info.sql ...
\i Schemas/MEMBER_DATA/Functions/tab_member_info.sql

\echo
\echo Releases/2022/member_data_load.sql ...
\cd ../../Src/POSTGRES
--\i Releases/2022/member_data_load.sql
\cd ../../Sample_Data/MEMBER_DATA

\echo
\echo Releases/2022/member_data_indexes_constraints.sql ...
--\i Releases/2022/member_data_indexes_constraints.sql

\echo
\echo Deployment successfully completed.