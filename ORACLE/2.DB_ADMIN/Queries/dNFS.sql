select * from v$dnfs_servers;
select * from v$dnfs_channels;
select * from v$dnfs_files;
select * from v$dnfs_stats;

create tablespace test_tbs datafile 'F:\nfs\data\test_tbs.dbf' size 10M;

alter system set enable_goldengate_replication = true scope=both;

select * from v$parameter where name = 'enable_goldengate_replication';

select * from v$process where pname like 'MS%' or pname like 'CP%' or pname like 'CX%';

