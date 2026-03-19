with rec as
 (
   select rec.*
     from json_each($1) as t,
          json_populate_record(null::twcache.counters, value) as rec
 )
 insert into twcache.counters(messageid, rts, favs)
      select messageid, rts, favs
        from rec
 on conflict (messageid)
   do update
         set rts  = counters.rts + excluded.rts,
             favs = counters.favs + excluded.favs
       where counters.messageid = excluded.messageid
