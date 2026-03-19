  select c.name, count(cp)
    from cities c, lateral (select name
                              from pubnames p
                             where (p.pos <@> c.pos) < 5) as cp
group by c.name
order by count(cp) desc
   limit 10;
