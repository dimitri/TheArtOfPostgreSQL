with counts as
  (
     select author, count(*)
       from commitlog
      where project = 'postgresql'
   group by date_trunc('week', ats), author
  )
  select author,
         sum(count),
         ceil(avg(count)) as weekly_avg,
         percentile_cont(array[0.5,0.99])
           within group (order by count)
           as percentiles_5_99
    from counts
group by author
order by sum desc;
