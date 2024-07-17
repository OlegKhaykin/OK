with
  p_list as
  (
    select 2011 + rownum num --+ trunc((rownum-1)/4)*10 + mod((rownum-1),4)+1 num
    from dual
    connect by rownum < 11
  )
--select * from p_list;  
  , sp_list as
  (
    select mod(rownum-1, 64) num
    from dual connect by rownum < 65
  )
--select * from sp_list;
select 'CREATE TABLE member_p'||num||' PARTITION OF member FOR VALUES IN ('||num||')' /*PARTITION BY HASH(member_id);'*/ cmd from sp_list;
select 'CREATE TABLE csid.ok_MemberHealthState_CURR_p'||ltrim(to_char(sp.num, '0000'))||' PARTITION OF csid.ok_MemberHealthState_CURR FOR VALUES WITH (MODULUS 1024, REMAINDER '||sp.num||') TABLESPACE pg_default;' cmd from sp_list sp;
select 'CREATE TABLE csid.ok_mhs_comm_2_1024_old_'||ltrim(to_char(sp.num, '0000'))||' PARTITION OF csid.ok_mhs_comm_2_1024_old FOR VALUES WITH (MODULUS 1024, REMAINDER '||sp.num||') TABLESPACE pg_default;' cmd from sp_list sp;
