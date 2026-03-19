select name, title
  from artist
       inner join album using(artistid)
 where artist.artistid = 1;
