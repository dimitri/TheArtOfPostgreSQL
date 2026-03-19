  select currency, validity, rate
    from rates
   where currency = 'Euro'
order by validity
   limit 10;
