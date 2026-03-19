  select forename, surname
    from results join drivers using(driverid)
   where position = 1
group by drivers.driverid;
