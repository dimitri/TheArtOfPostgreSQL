select array_agg(rowid)
  from tags
 where tag = 'blues' or tag = 'rhythm and blues';
