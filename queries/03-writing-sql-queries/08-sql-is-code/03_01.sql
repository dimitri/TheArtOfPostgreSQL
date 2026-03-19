with artist_albums as
 (
    select albumid, title
      from      album
           join artist using(artistid)
     where artist.name = 'AC/DC'
 )
  select title, name, milliseconds
    from artist_albums
          left join track
              using(albumid)
order by trackid;
