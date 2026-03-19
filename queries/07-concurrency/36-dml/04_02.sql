  select uname, message
    from tweet.message
         left join tweet.users using(userid)
order by messageid limit 4;
