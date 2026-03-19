begin;

drop table if exists access_log;

create table access_log
 (
   ip      inet,
   ts      timestamptz,
   request text,
   status  integer
 );

commit;
