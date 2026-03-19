  select tag, count(*)
    from hashtag, unnest(hashtags) as t(tag)
group by tag
order by count desc
   limit 10;
