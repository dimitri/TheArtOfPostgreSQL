explain (analyze, costs off)
select artist, title
  from lastfm.track
 where title ~* 'peace';
