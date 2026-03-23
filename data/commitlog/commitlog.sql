begin;

create schema if not exists commitlog;

drop table if exists commitlog.commitlog;

create table commitlog.commitlog
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

create index if not exists commitlog_commits_hash_idx
  on commitlog.commitlog(hash);

create index if not exists commitlog_commits_project_idx
  on commitlog.commitlog(project);

commit;
