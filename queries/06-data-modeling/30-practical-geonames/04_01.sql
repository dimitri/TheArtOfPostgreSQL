select count(*) as all,
       count(*) filter(where country_code is null) as no_country,
       count(*) filter(where admin1_code is null) as no_region,
       count(*) filter(where admin2_code is null) as no_district,
       count(*) filter(where feature_class is null) as no_class,
       count(*) filter(where feature_code is null) as no_feat
  from raw.geonames ;
