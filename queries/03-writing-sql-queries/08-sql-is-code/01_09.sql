SELECT name, title
  FROM artist, album
 WHERE artist.artistid = album.artistid
   AND artist.artistid = 1;
