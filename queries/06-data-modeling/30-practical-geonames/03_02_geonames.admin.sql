begin;

create schema if not exists geoname;

create table geoname.region
 (
  isocode   integer not null references geoname.country(isocode),
  regcode   text not null,
  name      text,
  geonameid bigint,

  primary key(isocode, regcode)
 );

insert into geoname.region
   with admin as
   (
     select regexp_split_to_array(code, '[.]') as code,
            name,
            geonameid
       from raw.admin1
   )
   select country.isocode as isocode,
          code[2] as regcode,
          admin.name,
          admin.geonameid
     from admin
          join geoname.country
            on country.iso = code[1];

create table geoname.district
 (
  isocode   integer not null,
  regcode   text not null,
  discode   text not null,
  name      text,
  geonameid bigint,

  primary key(isocode, regcode, discode),
  foreign key(isocode, regcode)
   references geoname.region(isocode, regcode)
 );

insert into geoname.district
   with admin as
   (
     select regexp_split_to_array(code, '[.]') as code,
            name,
            geonameid
       from raw.admin2
   )
     select region.isocode,
            region.regcode,
            code[3],
            admin.name,
            admin.geonameid
       from admin
            
            join geoname.country
              on country.iso = code[1]
            
            join geoname.region
              on region.isocode = country.isocode
             and region.regcode = code[2];

commit;
