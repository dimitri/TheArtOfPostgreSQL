with four_albums as
(
   select artistid
     from album
 group by artistid
   having count(*) = 4
)
  select artist.name, album, duration
    from four_albums
         join artist using(artistid),
         lateral get_all_albums(artistid)
order by artistid, duration desc;
