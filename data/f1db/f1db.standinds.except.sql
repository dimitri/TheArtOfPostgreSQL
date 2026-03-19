(
      select driverid,
             format('%s %s',
                    drivers.forename,
                    drivers.surname)
             as name
        
        from results
             join drivers using(driverid)
       
       where raceid = 972
         and points = 0
)     
except
(
      select driverid,
             format('%s %s',
                    drivers.forename,
                    drivers.surname)
             as name
        
        from results
             join drivers using(driverid)
       
       where raceid = 971
         and points = 0
)
;
