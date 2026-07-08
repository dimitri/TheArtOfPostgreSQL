select name, title
  from artist natural join album
 where artist.artist_id = 1;
