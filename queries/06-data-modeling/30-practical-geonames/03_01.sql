select geonameid, name, admin1_code, admin2_code
  from raw.geonames
 where country_code = 'FR'
 limit 5
offset 50;
