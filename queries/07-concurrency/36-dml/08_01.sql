select count(*) from foo;

begin;
truncate foo;
rollback;

select count(*) from foo;
