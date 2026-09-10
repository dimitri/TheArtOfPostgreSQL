create extension if not exists ip4r;

create table if not exists dbipcity
(
   country  text,
   region   text,
   city     text,
   iprange  ip4r,
   location point
);

create index dbipcity_iprange_idx on dbipcity using gist(iprange);
