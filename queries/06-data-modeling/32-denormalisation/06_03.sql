\pset format wrapped
\pset columns 57

 explain
  select currency, validity, rate
    from rates
   where currency = 'Euro'
     and validity @> date '2017-05-18';
