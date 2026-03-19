  select track.tid, track.title, tags.tag
    from tags
         join tid_tag tt on tags.rowid = tt.tag
         join tids on tids.rowid = tt.tid
         join lastfm.track on track.tid = tids.tid
   where track.artist = 'Aerosmith' 
     and tags.tag ~* 'favourite'
order by tid, tag;
