  select year,
         format('%s %s', forename, surname) as name,
         count(*) as ran,
         count(*) filter(where position = 1) as won,
         count(*) filter(where position is not null) as finished,
         sum(points) as points
    from      races
         join results using(raceid)
         join drivers using(driverid)
group by year, drivers.driverid
  having bool_and(position = 1) is true
order by year, points desc;
