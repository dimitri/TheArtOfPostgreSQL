begin;

create schema if not exists scan34;

drop table if exists scan34.access_log;

create table scan34.access_log
 (
   ip      inet,
   ts      timestamptz,
   request text,
   status  integer
 );

commit;
