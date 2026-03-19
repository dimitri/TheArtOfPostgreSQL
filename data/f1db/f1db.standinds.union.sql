(
      select raceid,
             'driver' as type,
             format('%s %s',
                    drivers.forename,
                    drivers.surname)
             as name,
             driverstandings.points
        
        from driverstandings
             join drivers using(driverid)
       
       where raceid = 972
         and points > 0
)     
union all
(
      select raceid,
             'constructor' as type,
             constructors.name as name,
             constructorstandings.points
        
        from constructorstandings
             join constructors using(constructorid)
       
       where raceid = 972
         and points > 0
)
order by points desc;
