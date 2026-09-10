-- Load the full, unfiltered DB-IP City Lite CSV into a staging table.
-- Run with cwd set to wherever dbip-city-lite.csv was downloaded (see
-- Makefile: `make load` execs psql with -w /tmp inside the container,
-- matching where dbip-city-lite.csv gets docker cp'd to).

drop table if exists dbip_raw;

create table dbip_raw (
    ip_start  text,
    ip_end    text,
    continent text,
    country   text,
    region    text,
    city      text,
    lat       float,
    lon       float
);

\copy dbip_raw from 'dbip-city-lite.csv' with (format csv)

select format('Loaded %s raw DB-IP rows.', count(*)) from dbip_raw;
