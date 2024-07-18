SELECT SYS_CONTEXT ('USERENV', 'CON_NAME') FROM DUAL;

select con_id, name, open_mode from v$pdbs;

alter pluggable database TENANTDB1 close;

alter pluggable database TENANTDB1 open read only;

select * from cdb_data_files;

create pluggable database tenantdb2 from tenantdb1
path_prefix = 'C:\ORACLE\ORADATA\OKWIN\TENANTDB2'
file_name_convert = ('C:\ORACLE\ORADATA\OKWIN\TENANTDB1','C:\ORACLE\ORADATA\OKWIN\TENANTDB2')
nologging;

alter pluggable database TENANTDB1 close;
alter pluggable database TENANTDB1 open;

-- In the new DB:
select * from v$tempfile;

alter database rename file 'C:\ORACLE\ORADATA\OKWIN\TENANTDB2\TENANTDB1_TEMP012016-01-01_04-11-37-PM.DBF'
to 'C:\ORACLE\ORADATA\OKWIN\TENANTDB2\TEMP01.DBF';

alter database open;

----
alter pluggable database tenantdb2 close;
drop pluggable database tenantdb2 including datafiles;