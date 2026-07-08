select name, title
  from artist
       inner join album using(artist_id)
 where artist.artist_id = 1;
