begin;

create table new_name (like name including all);

insert into new_name
     select <column list>
       from name
      where <restrictions>;
      
 drop table name;
alter table new_name rename to name;

commit;
