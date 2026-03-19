--
-- https://opendata.hauts-de-seine.fr/explore/dataset/archives-de-la-planete/information/?disjunctive.operateur&sort=identifiant_fakir
--

begin;

create schema if not exists opendata;

drop table if exists opendata.archives_planete;

create table opendata.archives_planete
 (
  id          text,
  inventory   text,
  orig_legend text,
  legend      text,
  location    text,
  date        text,
  operator    text,
  mission     text,
  place       text,
  themes      text,
  subjects    text,
  people      text,
  technic     text,
  format      text,
  owner       text,
  collection  text,
  license     text,
  continent   text,
  region      text,
  country     text,
  dept        text,
  city        text,
  photo       text,
  loc         point,
  locname     text
 );

\copy opendata.archives_planete from 'archives-de-la-planete.csv' with csv header delimiter ';'

commit;
