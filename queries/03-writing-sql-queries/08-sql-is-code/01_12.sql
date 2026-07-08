  select artist.name as artist,
         inspired.name as inspired,
         album.title as album,
         track.name as track
    from      artist
         join track on track.name = artist.name
         join album on album.album_id = track.album_id
         join artist inspired on inspired.artist_id = album.artist_id
   where artist.artist_id <> inspired.artist_id;
