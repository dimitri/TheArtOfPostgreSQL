begin;

create schema if not exists commitlog;

create table if not exists commitlog.commits
 (
   project      text,
   sha         text,
   author      text,
   author_date timestamptz,
   committer   text,
   commit_date timestamptz,
   subject     text,

   primary key(project, sha)
 );

create index if not exists commitlog_commits_sha_idx
  on commitlog.commits(sha);

create index if not exists commitlog_commits_project_idx
  on commitlog.commits(project);

commit;
