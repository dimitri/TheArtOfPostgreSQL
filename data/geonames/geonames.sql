begin;

create table geoname.geoname
 (
   geonameid         bigint primary key,
   name              text,
   location          point,
   isocode           integer,
   regcode           text,
   discode           text,
   class             char(1),
   feature           text,
   population        bigint,
   elevation         bigint,
   timezone          text,

   foreign key(isocode)
    references geoname.country(isocode),
   
   foreign key(isocode, regcode)
    references geoname.region(isocode, regcode),
    
   foreign key(isocode, regcode, discode)
    references geoname.district(isocode, regcode, discode),

   foreign key(class)
    references geoname.class(class),

   foreign key(class, feature)
    references geoname.feature(class, feature)
 );

insert into geoname.geoname
  with geo as
  (
     select geonameid,
            name,
            point(longitude, latitude) as location,
            country_code,
            admin1_code,
            admin2_code,
            feature_class,
            feature_code,
            population,
            elevation,
            timezone
       from raw.geonames
   )
     select geo.geonameid,
            geo.name,
            geo.location,
            country.isocode,
            region.regcode,
            district.discode,
            feature.class,
            feature.feature,
            population,
            elevation,
            timezone
       from geo
            left join geoname.country
              on country.iso = geo.country_code

            left join geoname.region
              on region.isocode = country.isocode
             and region.regcode = geo.admin1_code

            left join geoname.district
              on district.isocode = country.isocode
             and district.regcode = geo.admin1_code
             and district.discode = geo.admin2_code

           left join geoname.feature
             on feature.class = geo.feature_class
            and feature.feature = geo.feature_code;

create index on geoname.geoname using gist(location);

commit;

