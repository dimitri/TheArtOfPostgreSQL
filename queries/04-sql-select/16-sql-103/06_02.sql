select count(distinct(driverid))
  from results
       join drivers using(driverid)
 where position = 1;
