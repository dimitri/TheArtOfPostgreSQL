-- name: list-tracks-by-albumid
-- List the tracks of an album, includes duration and position
   select name as title,
          milliseconds * interval '1ms' as duration,
          (sum(milliseconds) over (order by trackid) - milliseconds)
            * interval '1ms' as "begin",
          sum(milliseconds) over (order by trackid)
            * interval '1ms' as "end",
          round(milliseconds / sum(milliseconds) over () * 100, 2) as pct
    from track
   where albumid = :id
order by trackid;
