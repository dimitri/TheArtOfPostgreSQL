  select name,
         milliseconds * interval '1 ms' as duration,
         pg_size_pretty(bytes) as bytes
    from track
   where albumid = 193
order by trackid;
