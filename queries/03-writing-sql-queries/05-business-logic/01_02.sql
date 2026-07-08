  select track.name as track, genre.name as genre
    from      track
         join genre using(genre_id)
   where album_id = 193
order by track_id;
