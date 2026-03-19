select follower.uname as follower,
       follower.bio as "follower's bio",
       following.uname as following
       
  from tweet.follower as follows
  
       join tweet.users as follower
         on follows.follower = follower.userid
         
       join tweet.users as following
         on follows.following = following.userid;
