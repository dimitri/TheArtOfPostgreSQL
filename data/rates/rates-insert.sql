---
--- Implement data transform step in ELT (Extract Load Transform)
---

begin;

insert into public.rates(currency, validity, rate)
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
