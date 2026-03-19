  select artist, title
    from lastfm.track
   where title % 'love'
group by artist, title
order by title <-> 'love'
   limit 10;
