  select c.name,
         array_to_string(array_agg(distinct(cp.name) order by cp.name), ', '),
         count(*)
    from cities c,
         lateral (select name
                    from pubnames p
                   where (p.pos <@> c.pos) < 5) as cp
   where c.name <> 'Westminster'
group by c.name, replace(replace(cp.name, 'The ', ''), 'And', '&')
order by count(*) desc
   limit 10;
