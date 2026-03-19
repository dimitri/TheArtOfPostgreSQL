  select artist.name as artist,
         inspired.name as inspired,
         album.title as album,
         track.name as track
    from      artist
         join track on track.name = artist.name
         join album on album.albumid = track.albumid
         join artist inspired on inspired.artistid = album.artistid
   where artist.artistid <> inspired.artistid;
