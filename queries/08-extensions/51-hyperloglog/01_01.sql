 select to_char(date, 'YYYY/MM') as month,
        round(#hll_union_agg(users)) as monthly
   from daily_uniques
group by month;
