   select pubs.name,
          round((pubs.pos <@> l.location)::numeric, 3) as miles,
          ceil(1609.34 * (pubs.pos <@> l.location)::numeric) as meters

     from dbipcity l
          left join lateral
          (
              select name, pos
                from pubnames
            order by pos <-> l.location
               limit 10
          ) as pubs on true

    where l.iprange >>= '129.67.242.154'
 order by meters;
