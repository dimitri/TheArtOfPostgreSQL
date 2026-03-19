select extract('year'
               from
               date_trunc('decade', date))
       as decade,
       count(*)
  from races
group by decade
order by decade;
