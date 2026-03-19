begin;

create schema if not exists tweet;

create table tweet.users
 (
   userid     bigserial primary key,
   uname      text not null,
   nickname   text,
   bio        text,
   picture    text,

   unique(uname)
 );

create table tweet.follower
 (
   follower   bigint not null references tweet.users(userid),
   following  bigint not null references tweet.users(userid),

   primary key(follower, following)
 );

create table tweet.list
 (
   listid     bigserial primary key,
   owner      bigint not null references tweet.users(userid),
   name       text not null,

   unique(owner, name)
 );

create table tweet.membership
 (
   listid     bigint not null references tweet.list(listid),
   member     bigint not null references tweet.users(userid),
   datetime   timestamptz not null,

   primary key(listid, member)
 );

create table tweet.message
 (
   messageid  bigserial primary key,
   userid     bigint not null references tweet.users(userid),
   datetime   timestamptz not null default now(),
   message    text not null,
   location   point,
   lang       text,
   url        text
 );

create type tweet.action_t
    as enum('rt', 'fav', 'de-rt', 'de-fav');

create table tweet.activity
 (
  id          bigserial primary key,
  messageid   bigint not null references tweet.message(messageid),
  datetime    timestamptz not null default now(),
  action      tweet.action_t not null,

  unique(messageid, datetime, action)
 );

commit;
