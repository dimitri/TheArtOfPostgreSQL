begin;

create schema if not exists tweet;

create table tweet.users
 (
   userid     bigserial primary key,
   uname      text not null,
   nickname   text not null,
   bio        text,
   picture    text,
   followers  bigint,
   following  bigint,
   listed     bigint,

   unique(uname)
 );

create table tweet.message
 (
   id         bigint primary key,
   userid     bigint references tweet.users(userid),
   datetime   timestamptz not null,
   message    text,
   favs       bigint,
   rts        bigint,
   location   point,
   lang       text,
   url        text
 );

commit;
