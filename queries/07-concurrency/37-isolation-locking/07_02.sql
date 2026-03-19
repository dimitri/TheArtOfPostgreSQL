  select   count(*) filter(where action = 'rt')
         - count(*) filter(where action = 'de-rt')
         as rts,
           count(*) filter(where action = 'fav')
         - count(*) filter(where action = 'de-fav')
         as favs
    from tweet.activity
         join tweet.message using(messageid)
   where messageid = :id;
