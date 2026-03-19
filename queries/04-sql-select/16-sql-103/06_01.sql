select distinct on (driverid)
       forename, surname
  from results
       join drivers using(driverid)
 where position = 1;
