  select messageid, 
         datetime::date as date,
         count(*) as count,
         count(distinct ipaddr) as uniques,
         count(*) - count(distinct ipaddr) as duplicates
    from tweet.visitor
   where messageid = 3
group by messageid, date
order by messageid, date
   limit 10;
