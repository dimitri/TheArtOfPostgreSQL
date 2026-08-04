-- Castle Ruins Dataset
-- Loaded by: taop castles
-- Source: OpenStreetMap via Overpass API (fetched at image build time)
--
-- The table uses a PostgreSQL-native point column (lon, lat) and a SP-GiST
-- index, making it ideal for kNN queries and bounding-box containment searches
-- that illustrate Space-Partitioned GiST's quadtree behaviour.
--
-- Example query (five nearest castles to Paris):
--   select name,
--          round((pos <-> point(2.35, 48.85))::numeric * 111.32, 1) as km
--     from castle_ruins
--    order by pos <-> point(2.35, 48.85)
--    limit 5;

drop table if exists castle_ruins;

create table castle_ruins (
    id    bigint  primary key,
    name  text    not null default '',
    lon   float   not null,
    lat   float   not null,
    pos   point   generated always as (point(lon, lat)) stored
);

\copy castle_ruins (id, name, lon, lat) from 'castles.csv' with (format csv, null '')

create index castle_ruins_spgist_idx
    on castle_ruins
 using spgist (pos);

select format('Loaded %s castle ruins with SP-GiST index.', count(*))
  from castle_ruins;
