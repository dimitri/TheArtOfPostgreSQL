select id, regexp_split_to_table(themes, ',')
  from opendata.archives_planete
 where id = 'IF39599';
