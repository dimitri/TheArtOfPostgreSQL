insert into tweet.message(userid, message)
     select userid, $2
       from tweet.users
      where users.uname = $1 or users.nickname = $1
