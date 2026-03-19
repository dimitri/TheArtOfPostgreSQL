select d::date as month,

       (d + interval '1 month' - interval '1 day')::date as month_end,

       (d + interval '1 month')::date as next_month,

       (d + interval '1 month')::date - d::date as days

  from generate_series(
                       date '2017-01-01',
                       date '2017-12-01',
                       interval '1 month'
                      )
       as t(d);
