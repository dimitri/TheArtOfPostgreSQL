  -- artists names used as track names by other artists
  select artist.name as artist,
         -- "inspired" is the other artist
         inspired.name as inspired,
         album.title as album,
         track.name as track
    from      artist
         /*
          * Here we join the artist name on the track name,
          * which is not our usual kind of join and thus
          * we don't use the using() syntax. For
          * consistency and clarity of the query, we use
          * the "on" join condition syntax through the
          * whole query.
          */
         join track
           on track.name = artist.name
         join album
           on album.album_id = track.album_id
         join artist inspired
           on inspired.artist_id = album.artist_id
   where artist.artist_id <> inspired.artist_id;
