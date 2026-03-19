create table tweet
 (
   id      bigint primary key,
   date    timestamptz,
   message text,
   tags    text
 );
