begin;

create schema if not exists v;
create schema if not exists cache;

create view v.season_points as
  select year as season, driver, constructor, points
    from seasons
         left join lateral
         /*
          * For each season, compute points by driver and by constructor.
          * As we're not interested into points per season for everybody
          * involved, we don't add the year into the grouping sets.
          */
         (
            select drivers.surname as driver,
                   constructors.name as constructor,
                   sum(points) as points
              
              from results
                   join races using(raceid)
                   join drivers using(driverid)
                   join constructors using(constructorid)
             
             where races.year = seasons.year
          
          group by grouping sets(drivers.surname, constructors.name)
          order by drivers.surname is not null, points desc
         )
         as points
         on true
order by year, driver is null, points desc;

create materialized view cache.season_points as
  select * from v.season_points;

create index on cache.season_points(season);

commit;
