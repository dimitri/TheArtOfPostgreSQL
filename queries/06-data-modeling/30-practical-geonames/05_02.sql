  select id,
         round((hashtag.location <-> geoname.location)::numeric, 3) as dist,
         country.iso,
         region.name as region,
         district.name as district
    from hashtag
         left join lateral
         (
            select geonameid, isocode, regcode, discode, location
              from geoname.geoname
          order by location <-> hashtag.location
             limit 1
         )
         as geoname
         on true
         left join geoname.country using(isocode)
         left join geoname.region using(isocode, regcode)
         left join geoname.district using(isocode, regcode, discode)
order by id
   limit 5;
