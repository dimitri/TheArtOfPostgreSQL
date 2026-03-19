select iprange, locid
  from geolite.blocks
 where iprange >>= '91.121.37.122';
