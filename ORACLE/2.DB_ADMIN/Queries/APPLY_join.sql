alter session set current_schema = ahmadmin; 

create type typ_varchar_tab as table of varchar2(30);
/

create table tst_ok 
(
  n number(10)  primary key,
  text          typ_varchar_tab
)
nested table text store as tst_ok_text;

insert into tst_ok values(1, typ_varchar_tab('One','Two'));
insert into tst_ok values(2, null);
commit;

select * from tst_ok;

-- I tried the following queries in 2 databases: 12c (12.2.0.1.0) and 19c (19.3.0.0.0):
select t.n, txt.* from tst_ok t left join table(t.text) txt on 1=1; -- 12c returns 2 rows, 19c returns 3 rows
select t.n, txt.* from tst_ok t outer apply t.text txt; -- 12c returns 2 rows, 19c returns 3 rows
select t.n, txt.* from tst_ok t left join lateral(select * from table(t.text)) txt on 1=1; -- both 12c and 19c return 3 rows 

select * from dba_registry;