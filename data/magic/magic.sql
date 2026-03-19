begin;

drop schema if exists magic cascade;

create schema magic;

create table magic.allsets(data jsonb);

commit;
