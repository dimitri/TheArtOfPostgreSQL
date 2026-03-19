begin;

drop type if exists rate_t cascade;

create type rate_t as
 (
   currency text,
   validity daterange,
   value    numeric
 );

create table rate of rate_t
 (
   exclude using gist (currency with =,
                       validity with &&)
 );
 
insert into rate(currency, validity, value)
     select currency, validity, rate
       from rates; 

commit;
