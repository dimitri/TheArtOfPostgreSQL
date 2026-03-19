begin;

drop table if exists commitlog;

create table commitlog
 (
   project   text,
   hash      text,
   author    text,
   ats       timestamptz,
   committer text,
   cts       timestamptz,
   subject   text,

   primary key(project, hash)
 );

\copy commitlog from 'pgloader.log' with csv delimiter ';'
\copy commitlog from 'postgres.log' with csv delimiter ';'

commit;
