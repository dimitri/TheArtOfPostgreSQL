  select track.artist, tags.tag, count(*)
    from tags
         join tid_tag tt on tags.rowid = tt.tag
         join tids on tids.rowid = tt.tid
         join lastfm.track on track.tid = tids.tid
   where track.artist = 'Aerosmith' 
group by artist, tags.tag
order by count desc
   limit 10;
