select a::text, b::text,
       (a=b)::text as "a=b",
       format('%s = %s',
              coalesce(a::text, 'null'),
              coalesce(b::text, 'null')) as op,
       format('is %s',
              coalesce((a=b)::text, 'null')) as result
  from (values(true), (false), (null)) v1(a)
       cross join
       (values(true), (false), (null)) v2(b);
