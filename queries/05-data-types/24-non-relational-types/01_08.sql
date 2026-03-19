  select name,
         substring(timezone, '/(.*)') as tz,
         count(*)
    from hashtag
    
         left join lateral
         (
            select *
              from geonames
          order by location <-> hashtag.location
             limit 1
         )
         as geoname
         on true
  
   where hashtags @> array['#Hiring', '#Retail']
   
group by name, tz
order by count desc
   limit 10;
