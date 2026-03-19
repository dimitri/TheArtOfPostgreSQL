explain (analyze, costs off)
   select artist, title
     from lastfm.track
   where title %> 'peas'
order by title <-> 'peas'
   limit 5;
