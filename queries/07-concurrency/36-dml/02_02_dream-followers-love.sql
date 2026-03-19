insert into tweet.follower
     select users.userid as follower,
            f.userid as following
       from      tweet.users
            join tweet.users f
              on f.uname = substring(users.bio from 'in love with #?(.*).')
      where users.bio ~ 'in love with';
