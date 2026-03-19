  select currency_code, currency_name, count(*)
    from raw.country
group by currency_code, currency_name
order by count desc
   limit 5;
