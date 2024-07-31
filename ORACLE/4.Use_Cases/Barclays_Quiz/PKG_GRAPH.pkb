create or replace package body pkg_graph as
  tab_graph               typ_int_pair_table;
  tab_norm                typ_int_pair_table;
  tab_visited_nodes       typ_int_table;
  n_idx                   pls_integer;
  v_str                   varchar2(256);
  
  procedure register_visited_node(p_node in int) is
  begin
    if p_node member of tab_visited_nodes then
      return;
    end if;
    
    tab_visited_nodes.extend(1);
    n_idx := n_idx+1;
    tab_visited_nodes(n_idx) := p_node;

    for r in
    (
      select distinct n.id
      from
      (
        select decode(id, p_node, parent_id, id) as id
        from table(tab_norm)
        where id = p_node or parent_id = p_node
      ) n
      left join table(tab_visited_nodes) vn
        on vn.column_value = n.id
      where vn.column_value is null
      order by n.id
    )
    loop
      register_visited_node(r.id);
    end loop;
  end register_visited_node;
  
  function traverse
  (
    p_graph       in sys_refcursor,
    p_start_node  in int
  ) return typ_int_table pipelined is
  begin
    fetch p_graph bulk collect into tab_graph;
    close p_graph;

    -- tab_graph -> tab_norm, to get rid of duplicates and self-loops:
    select distinct 
      greatest(id, parent_id) parent_id,
      least(id, parent_id) id
    bulk collect into tab_norm
    from table(tab_graph)
    where id <> parent_id; -- to eliminate self-loops 9-9
    
    tab_visited_nodes := typ_int_table();
    n_idx := 0;
    register_visited_node(p_start_node);

    for i in 1..n_idx loop
      pipe row (tab_visited_nodes(i));
    end loop;
  end traverse;
end pkg_graph;
/
