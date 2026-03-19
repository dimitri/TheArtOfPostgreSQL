begin;

   delete
     from tweet.users
    where userid = 22 and uname = 'CLAUDIUS'
returning *;

commit;
