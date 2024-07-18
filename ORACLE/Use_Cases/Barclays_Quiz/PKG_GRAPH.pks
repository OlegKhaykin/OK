create or replace package pkg_graph as
  subtype int             is number(3);
  type typ_int_table      is table of int;
  type typ_int_pair       is record(id int, parent_id int);
  type typ_int_pair_table is table of typ_int_pair;

  function traverse
  (
    p_graph       in sys_refcursor,
    p_start_node  in int
  )
  return typ_int_table pipelined;
end;
/