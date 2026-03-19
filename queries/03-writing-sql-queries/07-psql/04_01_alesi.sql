  select surname, races.name, races.year, results.position
    from results
         join drivers using(driverid)
         join races using(raceid)
   where drivers.surname = :'name'
         and position between 1 and 3
order by position
   limit :n;
