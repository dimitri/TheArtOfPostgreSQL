  select title, name, milliseconds
    from (
           select album_id, title
             from      album
                  join artist using(artist_id)
            where artist.name = 'AC/DC'
         )
           as artist_albums
         left join track
             using(album_id)
order by track_id;
