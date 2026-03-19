select *
 from      geolite.blocks
      join geolite.location using(locid)
where iprange >>= '74.125.195.147';
