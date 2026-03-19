select format('(%s)',
              string_agg(rowid::text, '&')
             )::query_int as query
  from tags
 where tag = 'blues' or tag = 'rhythm and blues';
