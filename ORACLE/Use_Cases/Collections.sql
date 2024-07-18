declare
  type  typ_hash  is table of varchar2(10) index by varchar2(30);
  type  typ_arr   is table of varchar2(10) index by pls_integer;
  hash  typ_hash;
  arr   typ_arr;
  idx   varchar2(30);
begin
  hash('First')  := 'One';
  hash('Second') := 'Two';
  hash('Third')  := 'Three';
  
  arr(1) := 'One';
  arr(5) := 'Five';
  arr(8) := 'Eight';
  
  dbms_output.put_line('hash: '||hash.FIRST||'-'||hash.LAST);
  
  idx := hash.FIRST;
  while idx is not null loop
    dbms_output.put_line('hash('||idx||'): '||hash(idx));
    idx := hash.NEXT(idx);
  end loop;
  
  dbms_output.new_line;
  dbms_output.put_line('arr: '||arr.FIRST||'-'||arr.LAST);
  for i in arr.FIRST..arr.LAST loop
    if arr.EXISTS(i) then
      dbms_output.put_line('arr('||i||'): '||arr(i));
    end if;
  end loop;
end;
/