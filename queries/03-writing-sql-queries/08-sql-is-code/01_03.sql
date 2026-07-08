  select name, milliseconds
    from album left join track using(album_id)
   where album_id = 1
order by 2;
