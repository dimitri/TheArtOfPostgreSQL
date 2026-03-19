     select lap, drivers.code, position,
            milliseconds * interval '1ms' as laptime
       from laptimes
            join drivers using(driverid)
      where raceid = 972
        and row(lap, position) > (1, 3)
   order by lap, position
fetch first 3 rows only;
