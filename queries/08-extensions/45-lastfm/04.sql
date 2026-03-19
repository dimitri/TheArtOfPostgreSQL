  select artist, count(*) 
    from lastfm.track
group by artist
order by count desc 
   limit 10;
