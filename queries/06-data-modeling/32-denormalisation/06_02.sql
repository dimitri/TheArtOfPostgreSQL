  select currency, validity, rate
    from rates
   where currency = 'Euro'
     and validity @> date '2017-05-18';
