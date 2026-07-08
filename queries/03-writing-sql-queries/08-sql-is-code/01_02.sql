  select title, name
    from album left join track using(album_id)
   where album_id = 1
order by 2;
