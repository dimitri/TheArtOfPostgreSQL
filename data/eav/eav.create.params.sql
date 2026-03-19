begin;

drop schema if exists eav cascade;
create schema eav;

create table eav.params
 (
   entity    text not null,
   parameter text not null,
   value     text not null,
   
   primary key(entity, parameter)
 );

commit;
