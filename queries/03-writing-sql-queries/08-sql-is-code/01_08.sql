  select title, name, milliseconds
    from (
           select albumid, title
             from      album
                  join artist using(artistid)
            where artist.name = 'AC/DC'
         )
           as artist_albums
         left join track
             using(albumid)
order by trackid;
