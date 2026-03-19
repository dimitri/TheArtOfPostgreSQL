select neighbour.iso,
       neighbour.name,
       neighbour.capital,
       neighbour.tld

  from geoname.neighbour as border
       
       join geoname.country as country
         on border.isocode = country.isocode
       
       join geoname.country as neighbour
         on border.neighbour = neighbour.isocode

 where country.iso = 'FR';
