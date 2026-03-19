  select extract(isodow from ats) as dow,
         to_char(ats, 'Day') as day,
         count(*) as commits,
         round(100.0*count(*)/sum(count(*)) over(), 2) as pct,
         repeat('■', (100*count(*)/sum(count(*)) over())::int) as hist
    from commitlog
   where project = 'postgresql'
group by dow, day
order by dow;
