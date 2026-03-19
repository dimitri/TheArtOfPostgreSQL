  select name, milliseconds
    from           album
         left join track using(albumid)
   where albumid = 1
order by trackid;
