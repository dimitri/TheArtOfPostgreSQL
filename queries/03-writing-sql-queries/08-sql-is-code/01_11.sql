select name, title
  from artist natural join album
 where artist.artistid = 1;
