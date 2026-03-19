create table if not exists cities
 (
  id  bigint, 
  pos point,
  name text
 );

create index on cities using gist(pos);
