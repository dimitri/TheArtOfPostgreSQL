\set season 2017

  select drivers.surname as driver,
         constructors.name as constructor,
         sum(points) as points
    
    from results
         join races using(raceid)
         join drivers using(driverid)
         join constructors using(constructorid)
   
   where races.year = :season

group by grouping sets(drivers.surname, constructors.name)
  having sum(points) > 150
order by drivers.surname is not null, points desc;
