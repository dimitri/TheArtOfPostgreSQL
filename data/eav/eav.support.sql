begin;

create table eav.support_contract_type
 (
   id   serial primary key,
   name text not null
 );
 
insert into eav.support_contract_type(name)
     values ('gold'), ('platinum');

create table eav.support_contract
 (
   id       serial primary key,
   type     integer not null references eav.support_contract_type(id),
   validity daterange not null,
   contract text,
   
   exclude using gist(type with =, validity with &&)
 );

create table eav.customer
 (
   id       serial primary key,
   name     text not null,
   address  text
 );

create table eav.support
 (
   customer  integer not null,
   contract  integer not null references eav.support_contract(id),
   instances integer not null,

   primary key(customer, contract),
   check(instances > 0)
 );

commit;
