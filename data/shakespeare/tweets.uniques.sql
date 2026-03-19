create table tweet.uniques
(
  messageid  bigint,
  date       date,
  visitors   hll,

  primary key(messageid, date)
);
