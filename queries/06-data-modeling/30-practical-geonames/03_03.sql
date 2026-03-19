select r.name, reg.name as region, d.name as district
  from raw.geonames r
       
       left join geoname.country
              on country.iso = r.country_code
       
       left join geoname.region reg
              on reg.isocode = country.isocode
             and reg.regcode = r.admin1_code
       
       left join geoname.district d
              on d.isocode = country.isocode
             and d.regcode = r.admin1_code
             and d.discode = r.admin2_code
 where country_code = 'FR'
 limit 5
offset 50;
