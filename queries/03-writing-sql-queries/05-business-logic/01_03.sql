  select name,
         milliseconds * interval '1 ms' as duration,
         pg_size_pretty(bytes::bigint) as bytes
    from track
   where album_id = 193
order by track_id;
