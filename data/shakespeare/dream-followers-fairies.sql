with fairies as
(
  select userid
    from tweet.users
   where bio ~ '#Fairies'
)
insert into tweet.follower(follower, following)
     select fairies.userid as follower,
            users.userid as following
       from fairies cross join tweet.users
      where users.bio ~ 'of the fairies';
