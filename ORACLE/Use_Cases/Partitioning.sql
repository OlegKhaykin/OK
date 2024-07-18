create sequence global_seq nocache;
 
create table t1
(
  t1_uid                integer constraint pk_t1 primary key,
  t1_id                 integer not null,
  val                   varchar2(30) not null,
  row_insert_ts         timestamp not null,
  row_effective_ts      timestamp not null,
  row_delete_ts         timestamp not null,
  row_next_effective_ts timestamp not null,
  effective_year        number(5) as (extract(year from least(row_delete_ts, row_next_effective_ts))) 
)
partition by range(effective_year) interval(1)
subpartition by hash(val) subpartitions 8
(
  partition old_data values less than (2011),
  partition y2011 values less than (2012),
  partition y2012 values less than (2013),
  partition y2013 values less than (2014),
  partition y2014 values less than (2015),
  partition y2015 values less than (2016),
  partition y9999 values less than (10000)
)
enable row movement;
comment on table t1 is '"Live" table';

create table t1_h
(
  t1_uid                integer constraint pk_t1_h primary key,
  t1_id                 integer not null,
  val                   varchar2(30) not null,
  row_insert_ts         timestamp not null,
  row_effective_ts      timestamp not null,
  row_delete_ts         timestamp not null,
  row_next_effective_ts timestamp not null,
  effective_year        number(5) as (extract(year from least(row_delete_ts, row_next_effective_ts)))
)
partition by range(effective_year)
subpartition by hash(val) subpartitions 8
(
  partition old_data values less than (2011)
);
comment on table t1_h is '"History" table';

create table b
(
  t1_uid                integer not null,
  t1_id                 integer not null,
  val                   varchar2(30) not null,
  row_insert_ts         timestamp not null,
  row_effective_ts      timestamp not null,
  row_delete_ts         timestamp not null,
  row_next_effective_ts timestamp not null,
  effective_year        number(5) as (extract(year from least(row_delete_ts, row_next_effective_ts))) 
) partition by hash(val) partitions 8;
comment on table b is '"Buffer" table';

select * from user_tab_partitions where table_name in ('T1', 'T1_H')
order by table_name;

-- Let's add some data:
insert into t1
(
  t1_uid, t1_id, val,
  row_insert_ts, row_effective_ts,
  row_delete_ts, row_next_effective_ts
)
values
(
  global_seq.nextval, global_seq.nextval, 'One',
  systimestamp, systimestamp,
  timestamp '9999-12-31 00:00:00', timestamp '9999-12-31 00:00:00'
);

insert into t1
(
  t1_uid, t1_id, val,
  row_insert_ts, row_effective_ts,
  row_delete_ts, row_next_effective_ts
)
values
(
  global_seq.nextval, global_seq.nextval, 'Two',
  systimestamp, systimestamp,
  timestamp '9999-12-31 00:00:00', timestamp '2013-12-31 00:00:00'
);

insert into t1
(
  t1_uid, t1_id, val,
  row_insert_ts, row_effective_ts,
  row_delete_ts, row_next_effective_ts
)
values
(
  global_seq.nextval, global_seq.nextval, 'Three',
  systimestamp, systimestamp,
  timestamp '2011-09-01 00:00:00', timestamp '2011-09-01 00:00:00'
);
commit;

select * from t1 order by t1_uid;
select * from t1 partition(y2011);
select * from t1 partition(y2013);
select * from t1 partition(y9999);

-- Let's delete the current row:
update t1 set row_delete_ts = systimestamp where t1_id = 1;
commit;

select * from t1 order by t1_uid;
select * from t1 partition(y2012); -- a row appeared here
select * from t1 partition(y9999); -- no rows

-- Let's move 2011 data from the "Live" table to the "History" table
-- using the "Buffer" table as intermidiary storage:
alter table t1 exchange partition y2011 with table b;
select * from t1;
select * from b;

alter table t1_h add partition y2011 values less than (2012);
alter table t1_h disable primary key;
alter table t1_h exchange partition y2011 with table b;
alter table t1_h enable primary key;

select * from t1_h;
