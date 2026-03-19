select artist, title
  from lastfm.track
 where title %> 'peace'

except

select artist, title
  from lastfm.track
 where title ~* 'peace';
