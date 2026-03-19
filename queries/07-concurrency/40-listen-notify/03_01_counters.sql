begin;

create schema if not exists twcache;

create table twcache.counters
 (
   messageid   bigint not null primary key,
   rts         bigint,
   favs        bigint
 );

commit;
