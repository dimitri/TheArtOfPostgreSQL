  select extract(year from ats) as year,
         count(*) filter(where project = 'postgresql') as postgresql,
         count(*) filter(where project = 'pgloader') as pgloader
    from commitlog
group by year
order by year;
