select *
  from      geolite.location l
       join geolite.blocks using(locid)
 where iprange >>= '129.67.242.154';
