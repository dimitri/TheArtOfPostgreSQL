select distinct on (ip)
       ip,
       set_masklen(ip::cidr, 27) as cidr_27,
       set_masklen(ip::cidr, 28) as cidr_28
  from access_log
 limit 10;
