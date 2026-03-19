set intervalstyle to postgres_verbose;

select interval '1 month',
       interval '2 weeks',
       2 * interval '1 week',
       78389 * interval '1 ms';
