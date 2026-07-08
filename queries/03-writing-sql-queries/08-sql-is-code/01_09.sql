SELECT name, title
  FROM artist, album
 WHERE artist.artist_id = album.artist_id
   AND artist.artist_id = 1;
