begin;

create schema if not exists raw;

-- Must be run as a Super User in your database instance
-- create extension if not exists btree_gist;

drop table if exists raw.rates, rates;

create table raw.rates
 (
  currency text,
  date     date,
  rate     numeric
 );

\copy raw.rates from 'rates.csv' with csv delimiter ';'

create table rates
 (
  currency text,
  validity daterange,
  rate     numeric,

  exclude using gist (currency with =,
                      validity with &&)
 );

insert into rates(currency, validity, rate)
     select currency,
            daterange(date,
                      lead(date) over(partition by currency
                                          order by date),
                      '[)'
                     )
            as validity,
            rate
       from raw.rates
   order by date;

commit;
