select iprange, country, region, city
  from dbipcity
 where iprange >>= '91.121.37.122';
