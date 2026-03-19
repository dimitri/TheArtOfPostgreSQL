select a::text as left, b::text as right,
       (a = b)::text as "=",
       (a <> b)::text as "<>",
       (a is distinct from b)::text as "is distinct",
       (a is not distinct from b)::text as "is not distinct from"
  from            (values(true),(false),(null)) t1(a)
       cross join (values(true),(false),(null)) t2(b);
