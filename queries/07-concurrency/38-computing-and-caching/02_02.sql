  select messageid,
         rts,
         nickname
    from tweet.message_with_counters
         join tweet.users using(userid)
   where messageid between 1 and 6
order by messageid;
