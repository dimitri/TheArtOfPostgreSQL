select album, duration
  from artist,
       lateral get_all_albums(artistid)
 where artist.name = 'Red Hot Chili Peppers';
