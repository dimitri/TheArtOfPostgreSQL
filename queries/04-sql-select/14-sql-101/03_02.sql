  select code, forename, surname,
         count(*) as wins
    from      drivers
         join results using(driverid)
   where position = 1
group by driverid
order by wins desc
limit 3;
