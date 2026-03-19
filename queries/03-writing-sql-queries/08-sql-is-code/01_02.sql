  select title, name
    from album left join track using(albumid)
   where albumid = 1
order by 2;
