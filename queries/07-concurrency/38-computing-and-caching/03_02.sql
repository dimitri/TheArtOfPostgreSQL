  select messageid,
         rts,
         nickname,
         substring(message from E'[^\n]+') as first_line
    from twcache.message
         join tweet.users using(userid)
   where messageid = 3
order by messageid;
