begin;

create schema if not exists counter;

create table counter.measures(tick int, nb int);

insert into counter.measures
     values (1, 0), (2, 10), (3, 20), (4, 30), (5, 40),
            (6, 0), (7, 20), (8, 30), (9, 60);

commit;
