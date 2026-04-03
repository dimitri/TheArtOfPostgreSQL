begin;

create schema if not exists raw;

-- Must be run as a Super User in your database instance
-- create extension if not exists btree_gist;

drop table if exists raw.rates, public.rates;

create table raw.rates
 (
   currency text,
   date     date,
   rate     numeric
 );

create table public.rates
 (
   currency text,
   validity daterange,
   rate     numeric,

   exclude using gist (currency with =,
                       validity with &&)
 );

commit;
