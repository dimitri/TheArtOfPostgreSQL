begin;

with deleted_rows as
(
    delete
      from tweet.users
     where not exists
           (
             select 1
               from tweet.message
              where userid = users.userid
           )
 returning *
)
select min(userid), max(userid),
       count(*),
       array_agg(uname)
  from deleted_rows;

commit;
