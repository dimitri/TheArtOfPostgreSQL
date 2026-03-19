\set season 'date ''1978-01-01'''

  select forename,
         surname,
         constructors.name as constructor,
         count(*) as races,
         count(distinct status) as reasons

    from drivers
         join results using(driverid)
         join races using(raceid)
         join status using(statusid)
         join constructors using(constructorid)

   where date >= :season
     and date <  :season + interval '1 year'
     and not exists
         (
           select 1
             from results r
            where position is not null
              and r.driverid = drivers.driverid
              and r.resultid = results.resultid
         )
group by constructors.name, driverid
order by count(*) desc;
