  select to_char(date, 'YYYY/MM') as month, 
         to_char(date, 'YYYY IW') as week, 
         round(# hll_union_agg(visitors)) as unique,
         sum(# visitors)::bigint as sum
    from tweet.uniques
group by grouping sets((month), (month, week))
order by month nulls first, week nulls first;
