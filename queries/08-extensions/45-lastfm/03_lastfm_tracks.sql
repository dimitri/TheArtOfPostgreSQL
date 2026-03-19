begin;

create schema if not exists lastfm;

drop table if exists lastfm.track;

create table lastfm.track
 (
   tid    text,
   artist text,
   title  text
 );

commit;
