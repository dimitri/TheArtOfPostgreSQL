  select races.date,
         races.name,
         drivers.surname as pole_position,
         results.position
    from races
         /*
          * We want only the pole position from the races
          * know the result of and still list the race when
          * we don't know the results.
          */
         left join results
                on races.raceid = results.raceid
               and results.grid = 1
         left join drivers using(driverid)
   where     date >= '2017-05-01'
         and date < '2017-08-01'
order by races.date;
