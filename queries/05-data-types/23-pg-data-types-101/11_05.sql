\set day '2017-06-01'

  select ats::time,
         substring(hash from 1 for 8) as hash,
         substring(subject from 1 for 40) || '…' as subject
    from commitlog
   where project = 'postgresql'
     and ats >= date :'day'
     and ats  < date :'day' + interval '1 day'
order by ats;
