select a, b
  from (values(true), (false), (null)) v1(a)
       cross join
       (values(true), (false), (null)) v2(b)
where a is null;
