set lc_time to 'fr_FR';

  select to_char(ats, 'TMDay TMDD TMMonth, HHam') as time,
         substring(hash from 1 for 8) as hash,
         substring(subject from 1 for 40) || '…' as subject
    from commitlog
   where project = 'postgresql'
     and ats >= date :'day'
     and ats  < date :'day' + interval '1 day'
order by ats;
