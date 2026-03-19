  select class, feature, description, count(*)
    from feature
         left join geoname using(class,feature)
group by class, feature
order by count desc
   limit 10;
