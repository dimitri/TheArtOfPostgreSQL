create or replace function random
 (
  a timestamptz,
  b timestamptz
 )
 returns timestamptz
 volatile
 language sql
as $$
  select a
         + random(0, extract(epoch from (b-a))::int)
           * interval '1 sec';
$$;
