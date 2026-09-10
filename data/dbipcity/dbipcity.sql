-- dbipcity: IP geolocation data from DB-IP City Lite, replacing the old
-- MaxMind GeoLite2 dataset (MaxMind's license changed and this repo no
-- longer redistributes it).
--
-- Source: DB-IP City Lite (September 2026 snapshot), CC BY 4.0 --
-- https://db-ip.com/db/download/ip-to-city-lite -- redistribution requires
-- attribution: "IP Geolocation by DB-IP" linking to https://db-ip.com.
--
-- dbipcity.csv.xz is a filtered slice of the full ~7.7M-row global file:
-- IPv4 only (ip4r doesn't cover IPv6), Great Britain (all of it -- "GB" is
-- the ISO code for the whole UK), France, and the whole US -- GB/FR cover
-- the book's ip4r worked examples (Roubaix FR, Oxford GB), the whole US
-- also covers the hashtag/tweet chapter's US-wide geolocated data.
-- 1,308,590 rows, 9.1 MB compressed (xz -9e; 79 MB decompressed).
--
-- Committed compressed: xz -9e beats gzip by a wide margin on this data and
-- is available everywhere. `taop dbipcity` decompresses it to dbipcity.csv
-- before running this file (see tooling/taop/dbipcity.lisp) -- this script
-- expects that plain CSV to already exist alongside it.
--
-- Unlike MaxMind's legacy format (one "location" row shared by many IP
-- blocks, joined by a synthetic id), DB-IP ships one row per IP block with
-- country/region/city/coordinates already on it -- no separate location
-- table to join, so this is one table, not two.
--
-- Example query (nearest pubs to an Oxford, GB IP):
--   select country, region, city, iprange
--     from dbipcity
--    where iprange >>= '129.67.242.154';

create extension if not exists ip4r;

drop table if exists dbipcity;

create table dbipcity (
    country  text,
    region   text,
    city     text,
    iprange  ip4r,
    location point
);

\copy dbipcity (country, region, city, iprange, location) from 'dbipcity.csv' with (format csv)

create index dbipcity_iprange_idx on dbipcity using gist (iprange);

select format('Loaded %s dbipcity blocks (GB, FR, US).', count(*))
  from dbipcity;
