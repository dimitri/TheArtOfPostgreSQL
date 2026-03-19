  select year,
         drivers.code,
         format('%s %s', forename, surname) as name,
         count(*)
    from results
         join races using(raceid) 
         join drivers using(driverid)
   where grid = 1
     and position = 1
group by year, drivers.driverid
order by count desc
   limit 10;
