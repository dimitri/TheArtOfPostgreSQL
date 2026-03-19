begin;

alter table f1db.circuits add column position point;
update f1db.circuits set position = point(lng,lat);
create index on f1db.circuits using gist(position);

commit;
