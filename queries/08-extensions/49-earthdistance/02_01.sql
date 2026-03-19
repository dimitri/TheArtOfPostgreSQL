  select name, round((pos <@> point(-0.12,51.516))::numeric, 3) as miles
    from pubnames
order by pos <-> point(-0.12,51.516) desc
   limit 5;
