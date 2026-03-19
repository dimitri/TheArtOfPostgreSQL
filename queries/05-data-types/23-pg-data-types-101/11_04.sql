with perc_arrays as
  (
       select project,
              avg(cts-ats) as average,
              percentile_cont(array[0.5, 0.9, 0.95, 0.99])
                 within group(order by cts-ats) as parr
         from commitlog
        where ats <> cts
    group by project
  )
 select project, average,
        parr[1] as median,
        parr[2] as "%90th",
        parr[3] as "%95th",
        parr[4] as "%99th"
   from perc_arrays;
