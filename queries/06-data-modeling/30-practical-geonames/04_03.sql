  select continent.name,
         count(*),
         round(100.0 * count(*) / sum(count(*)) over(), 2) as pct,
         repeat('■', (100 * count(*) / sum(count(*)) over())::int) as hist
    from geoname.geoname
         join geoname.country using(isocode)
         join geoname.continent
           on continent.code = country.continent
group by continent.name
order by continent.name;
