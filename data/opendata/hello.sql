begin;

drop table if exists hello;

create table hello
 (
  language text,
  hello    text
 );


\copy hello from 'hello.csv' with csv delimiter '	'

commit;
