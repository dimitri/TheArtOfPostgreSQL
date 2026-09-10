-- Filter the raw DB-IP City Lite load (dbip_raw, see load.sql / `make
-- load`) down to what the book's worked examples need: IPv4 only (ip4r
-- doesn't cover IPv6 -- it's a separate ip6r type in the same extension --
-- and DB-IP's "IP to City Lite" file includes both), and Great Britain
-- (all of it: England, Scotland, Wales, Northern Ireland -- "GB" is the
-- ISO code for the whole UK, not just the island), France, and the whole
-- US. GB/FR cover the book's ip4r worked examples (Roubaix FR, Oxford GB);
-- the whole US -- not just California -- also covers the hashtag/tweet
-- chapter's US-wide geolocated data. See ../README.md.
--
-- ip_start/ip_end (plain dotted-decimal) fold directly into ip4r -- no
-- pgloader transform needed, unlike the old MaxMind format's integer
-- encoding.

create extension if not exists ip4r;

drop table if exists dbipcity;

create table dbipcity as
select country, region, city,
       ip4r(ip_start::ip4, ip_end::ip4) as iprange,
       point(lon, lat) as location
  from dbip_raw
 where ip_start !~ ':'
   and country in ('GB', 'FR', 'US');

create index dbipcity_iprange_idx on dbipcity using gist (iprange);

\copy (select country, region, city, iprange, location from dbipcity order by iprange) to 'dbipcity.csv' with (format csv)

select format('Wrote %s filtered rows to dbipcity.csv.', count(*)) from dbipcity;
