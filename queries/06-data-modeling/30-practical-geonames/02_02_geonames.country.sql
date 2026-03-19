begin;

create schema if not exists geoname;

create table geoname.continent
 (
  code    char(2) primary key,
  name    text
 );

insert into geoname.continent(code, name)
     values ('AF', 'Africa'),
            ('NA', 'North America'),
            ('OC', 'Oceania'),
            ('AN', 'Antarctica'),
            ('AS', 'Asia'),
            ('EU', 'Europe'),
            ('SA', 'South America');

create table geoname.country
 (
  isocode   integer primary key,
  iso       char(2) not null,
  iso3      char(3) not null,
  fips      text,
  name      text,
  capital   text,
  continent char(2) references geoname.continent(code),
  tld       text,
  geonameid bigint
 );

insert into geoname.country
     select isocode, iso, iso3, fips, name,
            capital, continent, tld, geonameid
       from raw.country;

create table geoname.neighbour
 (
  isocode   integer not null references geoname.country(isocode),
  neighbour integer not null references geoname.country(isocode),

  primary key(isocode, neighbour)
 );

insert into geoname.neighbour
   with n as(
     select isocode,
            regexp_split_to_table(neighbours, ',') as neighbour
       from raw.country
   )
   select n.isocode,
          country.isocode
     from n
          join geoname.country
            on country.iso = n.neighbour;

commit;
