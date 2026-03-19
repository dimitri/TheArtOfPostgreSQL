  select c.name as city, p.name,
         round((pos <@> point(-0.12,51.516))::numeric, 3) as miles
    from pubnames p,
         lateral (select name
                    from cities c
                order by c.pos <-> p.pos
                   limit 1) c
order by pos <-> point(-0.12,51.516) desc
   limit 5;
