create extension if not exists ip4r;
create schema if not exists geolite;

create table if not exists geolite.location
(
   locid      integer primary key,
   country    text,
   region     text,
   city       text,
   postalcode text,
   location   point,
   metrocode  text,
   areacode   text
);
       
create table if not exists geolite.blocks
(
   iprange    ip4r,
   locid      integer
);

create index blocks_ip4r_idx on geolite.blocks using gist(iprange);

