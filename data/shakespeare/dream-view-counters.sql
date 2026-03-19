create view tweet.message_with_counters
      as
  select messageid,
         message.userid,
         message.datetime,
         message.message,
           count(*) filter(where action = 'rt')
         - count(*) filter(where action = 'de-rt')
         as rts,
           count(*) filter(where action = 'fav')
         - count(*) filter(where action = 'de-fav')
         as favs,
         message.location,
         message.lang,
         message.url
    from tweet.activity
         join tweet.message using(messageid)
group by message.messageid, activity.messageid;
