with t(query) as (
     select format('(%s)',
                   array_to_string(array_agg(rowid), '&')
                  )::query_int as query
      from tags
     where tag = 'blues' or tag = 'rhythm and blues'
)
select count(*) 
  from track_tags join t on tags @@ query; 
