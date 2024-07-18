create table t1(n number primary key, v varchar(200));
create table t2(n number primary key, v varchar(200));

insert into t1 values(1, 'T1-one');
insert into t1 values(2, 'T1-two');
insert into t2 values(1, 'T2-one');
insert into t2 values(3, 'T2-three');
commit;

select
  t1.n t1_n, t1.v t1_v,
  t2.n t2_n, t2.v t2_v
from t1
left join t2 on t2.n = t1.n;

select
  t1.n t1_n, t1.v t1_v,
  t2.n t2_n, t2.v t2_v
from t1
right join t2 on t2.n = t1.n;



