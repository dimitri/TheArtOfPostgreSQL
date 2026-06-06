begin;

create schema if not exists sample;

drop table if exists sample.geonames;

create table sample.geonames
   as select /*
              * We restrict the “export” to some columns only, so as to
              * further reduce the size of the exported file available to
              * download with the book.
              */
             geonameid,
             name,
             longitude,
             latitude,
             feature_class,
             feature_code,
             country_code,
             admin1_code,
             admin2_code,
             population,
             elevation,
             timezone
             /*
              * We only keep 1% of the 11 millions rows here.
              */
        from raw.geonames TABLESAMPLE bernoulli(1);

\copy sample.geonames to 'allCountries.sample.copy'

commit;
