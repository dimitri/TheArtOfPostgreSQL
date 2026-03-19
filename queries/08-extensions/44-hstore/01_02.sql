select kv, 
       kv->'a' as "kv -> a", 
       kv-> array['a', 'c'] as "kv -> [a, c]"
  from (
        values ('a=>1,a=>2'::hstore),
               ('a=>5,c=>10')
       )
       as t(kv);
