select name, password from sys.user$; -- only as SYS

select * from v$database;
select * from nls_database_parameters;
select * from v$parameter where name in ('os_authent_prefix','db_domain');

--==============================================================================
select * from v$containers;
select * from v$pdbs;
select * from dba_pdbs;

select * from cdb_services;
select * from dba_services;

select
  sys_context('userenv','con_id') con_id,
  sys_context ('USERENV', 'CON_NAME') con_name
from dual;

select * from cdb_objects;
select * from proxy_users;

alter pluggable database PDB1 open; -- for the laptop database
alter pluggable database PDB1 close;
--alter pluggable database TENANTDB1 open instances=all; -- for the RAC database
--alter pluggable database TENANTDB1 close immediate instances=all;

select * from cdb_data_files;
select * from dba_data_files;
select con_id, tablespace_name, file_name from cdb_temp_files;
select * from dba_redo_log;

--==============================================================================
-- Create a common user - i.e. a User that is present in all Containers of a CDB
alter session set container = CDB$ROOT; -- unless you are already in the Root Container
select * from v$parameter where name = 'common_user_prefix';

create user c##oleg identified by m default tablespace users temporary tablespace temp;
alter user c##oleg set container_data=all container=current;
grant connect, resource, set container, logmining, unlimited tablespace, select_catalog_role to c##oleg container=all;

