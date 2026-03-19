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
