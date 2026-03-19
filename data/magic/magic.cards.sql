begin;

drop table if exists magic.sets, magic.cards;

create table magic.sets
    as
select key as name, value - 'cards' as data
  from magic.allsets, jsonb_each(data);
  
create table magic.cards
    as
  with collection as
  (
     select key as set,
            value->'cards' as data
       from magic.allsets,
            lateral jsonb_each(data)
  )
  select set, jsonb_array_elements(data) as data
    from collection;

commit;
