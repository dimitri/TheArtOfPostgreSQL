create or replace function get_all_albums
 (
   in  name     text,
   out album    text,
   out duration interval
 )
returns setof record
language sql
as $$
  select album.title as album,
         sum(milliseconds) * interval '1 ms' as duration
    from album
         join artist using(artist_id)
         left join track using(album_id)
   where artist.name = get_all_albums.name
group by album
order by album;
$$;
