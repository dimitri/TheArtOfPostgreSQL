begin;

drop schema if exists geoname cascade;
create schema geoname;

create table geoname.class
 (
  class        char(1) not null primary key,
  description  text
 );

insert into geoname.class (class, description)
     values ('A', 'country, state, region,...'),
            ('H', 'stream, lake, ...'),
            ('L', 'parks,area, ...'),
            ('P', 'city, village,...'),
            ('R', 'road, railroad '),
            ('S', 'spot, building, farm'),
            ('T', 'mountain,hill,rock,... '),
            ('U', 'undersea'),
            ('V', 'forest,heath,...');

create table geoname.feature
 (
  class       char(1) not null references geoname.class(class),
  feature     text    not null,
  description text,
  comment     text,

  primary key(class, feature)
 );

insert into geoname.feature
     select substring(code from 1 for 1) as class,
            substring(code from 3) as feature,
            description,
            comment
       from raw.feature
      where feature.code <> 'null';

commit;
