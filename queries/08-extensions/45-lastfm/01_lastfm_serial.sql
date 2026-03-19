begin;

alter table tags add column rowid serial;
alter table tids add column rowid serial;

commit;
