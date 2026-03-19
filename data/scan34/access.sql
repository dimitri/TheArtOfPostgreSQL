begin;

drop table if exists access_log;

create table access_log
 (
  ip      inet,
  ts      timestamptz,
  request text,
  status  integer
 );

\copy access_log from 'access.csv' with csv delimiter ';'

commit;

