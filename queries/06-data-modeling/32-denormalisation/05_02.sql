insert into archive.older_versions(table_name, action, data)
     select 'hashtag', 'delete', row_to_json(hashtag)
       from hashtag
      where id = 720554371822432256
  returning table_name, date, action, jsonb_pretty(data) as data;
