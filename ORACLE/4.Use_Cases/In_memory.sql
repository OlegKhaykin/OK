alter system set inmemory_size=300M scope=spfile;
alter session set optimizer_inmemory_aware=true;

select * from v$im_segments;
select * from v$im_header;
select * from v$im_smu_head;
select * from v$im_column_level;

select * from v$parameter where name = 'inmemory_size';

select * from dba_registry;

create table countries
(
  code  varchar2(3) constraint pk_countries primary key,
  name  varchar2(30) not null
);

create table provinces
(
  country_code  varchar2(3) not null,
  province_code varchar2(5) not null,
  name          varchar2(30) not null,
  constraint fk_province_country foreign key(country_code) references countries on delete cascade,
  constraint pk_provinces primary key (country_code, province_code)
);

create table customers
(
  id            integer generated always as identity constraint pk_customers primary key,
  name          varchar2(30) not null,
  country_code  varchar2(3) not null,
  province_code varchar2(3),
  constraint fk_customer_province foreign key(country_code, province_code) references provinces on delete cascade,
  constraint fk_customer_country foreign key(country_code) references countries on delete cascade
);

drop table orders purge;

create table orders
(
   id integer generated always as identity constraint pk_orders primary key,
   order_dt     date default sysdate not null,
   customer_id  integer,
   status varchar2(10) default '1-New' not null constraint chk_order_status check(status in ('1-New','2-WIP','3-Completed','4-Cancelled'))
) 
row store compress basic 
inmemory memcompress for query
--row store advanced -- if you bougth Advanced Compression option ($11,500 per processor or $230 per named user)
--column store compress for query high -- only in Exadata or zFS
;

insert into countries values('USA','United States Of America');
insert into provinces values('USA', 'NJ', 'New Jersey');
insert into customers(name, country_code) values('Customer 1', 'USA');

select * from customers;

insert /*+ append*/ into orders(customer_id) select value(t) from table(oleg.split_string('1,1,1,1,1')) t;

select blocks, pct_free, compression, compress_for, inmemory
from user_tables
where table_name = 'ORDERS';

alter table orders inmemory;


create table tst_objects inmemory
--distribute by partition
distribute by rowid range
duplicate -- works on Exadata or ODA only
--duplicate all -- works on Exadata or ODA only
as select * from all_objects;

select count(1) from tst_objects;
select sum(bytes)/1024/1024 mbytes from user_segments where segment_name = 'TST_OBJECTS';

select * from v$parameter where name = 'inmemory_size';
select * from v$im_segments;
select * from v$im_header;
select * from v$im_column_level;

select * from orders;


