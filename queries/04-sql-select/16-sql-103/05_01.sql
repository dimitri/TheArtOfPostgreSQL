  select extract(year from races.date) as season,
         count(*)
           filter(where status = 'Accident') as accidents
    
    from results
         join status using(statusid)
         join races using(raceid)

group by season
order by accidents desc
   limit 5;
