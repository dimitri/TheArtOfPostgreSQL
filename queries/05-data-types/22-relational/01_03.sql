select date(date '0001-01-01' + x * interval '1 day')
  from generate_series (-2, 1) as t(x);
