  select track.name as track, genre.name as genre
    from      track
         join genre using(genreid)
   where albumid = 193
order by trackid;
