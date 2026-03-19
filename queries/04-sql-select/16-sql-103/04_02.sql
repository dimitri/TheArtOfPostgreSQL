    select drivers.surname as driver,
           constructors.name as constructor,
           sum(points) as points
      
      from results
           join races using(raceid)
           join drivers using(driverid)
           join constructors using(constructorid)
     
     where drivers.surname in ('Prost', 'Senna')
  
  group by rollup(drivers.surname, constructors.name);
