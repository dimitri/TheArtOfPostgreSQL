begin;

drop schema if exists raw cascade;
create schema raw;

create table raw.geonames
 (
   geonameid         bigint,
   name              text,
   asciiname         text,
   alternatenames    text,
   latitude          double precision,
   longitude         double precision,
   feature_class     text,
   feature_code      text,
   country_code      text,
   cc2               text,
   admin1_code       text,
   admin2_code       text,
   admin3_code       text,
   admin4_code       text,
   population        bigint,
   elevation         bigint,
   dem               bigint,
   timezone          text,
   modification      date
 );

create table raw.country
 (
  iso                 text,
  iso3                text,
  isocode             integer,
  fips                text,
  name                text,
  capital             text,
  area                double precision,
  population          bigint,
  continent           text,
  tld                 text,
  currency_code       text,
  currency_name       text,
  phone               text,
  postal_code_format  text,
  postal_code_regex   text,
  languages           text,
  geonameid           bigint,
  neighbours          text,
  fips_equiv          text
 );

\copy raw.country from 'countryInfoData.txt' with csv delimiter E'\t'

create table raw.feature
 (
  code        text,
  description text,
  comment     text
 );

\copy raw.feature from 'featureCodes_en.txt' with csv delimiter E'\t'

create table raw.admin1
 (
  code       text,
  name       text,
  ascii_name text,
  geonameid  bigint
 );

\copy raw.admin1 from 'admin1CodesASCII.txt' with csv delimiter E'\t'

create table raw.admin2
 (
  code       text,
  name       text,
  ascii_name text,
  geonameid  bigint
 );

\copy raw.admin2 from 'admin2Codes.txt' with csv delimiter E'\t'

commit;

