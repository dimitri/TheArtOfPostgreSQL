-- name: top-artists-by-album
-- Get the list of the N artists with the most albums
  select artist.name, count(*) as albums
    from           artist
         left join album using(artistid)
group by artist.name
order by albums desc
   limit :n;
