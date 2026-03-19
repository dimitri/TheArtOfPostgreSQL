with accidents as
 (
    select extract(year from races.date) as season,
           count(*) as participants,
           count(*) filter(where status = 'Accident') as accidents
      from results
           join status using(statusid)
           join races using(raceid)
  group by season
 )
  select season,
         round(100.0 * accidents / participants, 2) as pct,
         repeat(text '■',
                ceil(100*accidents/participants)::int
               )
         as bar
    from accidents
   where season between 1974 and 1990
order by season;
