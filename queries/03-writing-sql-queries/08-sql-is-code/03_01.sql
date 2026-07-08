with artist_albums as
 (
    select album_id, title
      from      album
           join artist using(artist_id)
     where artist.name = 'AC/DC'
 )
  select title, name, milliseconds
    from artist_albums
          left join track
              using(album_id)
order by track_id;
