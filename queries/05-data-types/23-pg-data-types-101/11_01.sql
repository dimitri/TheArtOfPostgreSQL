  select project, hash, author, ats, committer, cts, subject
    from commitlog
   where project = 'postgresql'
order by ats desc
   limit 1;
