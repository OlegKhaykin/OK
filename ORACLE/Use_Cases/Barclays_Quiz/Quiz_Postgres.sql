with recursive
  graph as 
  (
    select  1 id,  2 parent_id union all 
    select  1 id,  3 parent_id union all 
    select  4 id,  3 parent_id union all 
    select  5 id,  4 parent_id union all 
    select  6 id,  5 parent_id union all 
    select  7 id,  6 parent_id union all 
    select  8 id,  7 parent_id union all 
    select  7 id,  8 parent_id union all
    select  8 id, 10 parent_id union all
    select  9 id,  9 parent_id union all 
    select 12 id, 11 parent_id
    union all -- I added the following 3 edges to test how cycles are handled:
    select  13 id, 14 parent_id union all
    select  14 id, 15 parent_id union all
    select  15 id, 13 parent_id
  ),
  norm as
  (
    select
      row_number() over(order by id, parent_id) rnum,
      id, parent_id
    from
    (
      select distinct 
        greatest(id, parent_id) parent_id,
        least(id, parent_id) id
      from graph
      where id <> parent_id -- to eliminate 9-9
    ) q
  ),
  h(rnum, lvl, id) as
  (
    select 0::bigint, 1, 1 -- here the user should specify the starting node, 1 in this case
    union all
    select
      n.rnum, h.lvl+1,
      case n.id when h.id then n.parent_id else n.id end
    from h
    join norm n
      on (n.id = h.id or n.parent_id = h.id)
     and n.rnum <> h.rnum
  )
select id from
(
  select
    h.*,
    row_number() over(partition by h.id order by h.lvl) rn
  from h
) q
where rn = 1
order by lvl, id;