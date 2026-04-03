begin;

drop type if exists public.rate_t cascade;

create type public.rate_t as
 (
   currency text,
   validity daterange,
   value    numeric
 );

create table public.rate of public.rate_t
 (
   exclude using gist (currency with =,
                       validity with &&)
 );
 
insert into public.rate(currency, validity, value)
     select currency, validity, rate
       from public.rates; 

commit;
