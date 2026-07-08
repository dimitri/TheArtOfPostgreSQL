# k-Nearest-Neighbour Search with `<->`

"Find the closest *N* things to here" is one of those questions that feels like
it needs a special search engine. In PostgreSQL it's a one-line `ORDER BY` — and
with the right index it answers in well under a millisecond.

We use the **pubnames** dataset (loaded with `taop pubnames`): every pub in the
United Kingdom from OpenStreetMap, stored as a `point`.

```sql
\d pubnames
```

```
 Column |  Type  | description
--------+--------+-----------------------------
 id     | bigint | OSM node id
 pos    | point  | (longitude, latitude)
 name   | text   | the pub name
```

## The Problem

Standing at Holborn in London — longitude `-0.12`, latitude `51.516` — which
ten pubs are nearest?

## The Query

PostgreSQL's `point` type has a *distance* operator, `<->`. Order by it and you
get the rows sorted nearest-first; `limit` stops at ten:

```sql
  select id, name, pos
    from pubnames
order by pos <-> point(-0.12, 51.516)
   limit 10;
```

```
    id     |          name          |           pos
-----------+------------------------+-------------------------
  21593238 | All Bar One            | (-0.1192746,51.5163499)
  26848690 | The Shakespeare's Head | (-0.1194731,51.5167871)
 371049718 | The Newton Arms        | (-0.1209811,51.5163032)
       ...
```

Mapped over the streets of Holborn, the result speaks for itself — the search
point in red, the ten nearest pubs picked out and named. The same query, with
a PostGIS/SVG tail bolted on: OSM roads from `osm_london.roads` for context,
clipped to a window around the 10 nearest pubs, plus a marker for the search
point and one per pub. Run it and switch to the **Map** tab on its output:

```sql
with search as (
  select point(-0.12, 51.516) as pt
),
nearest as (
  select id, name, pos,
         row_number() over (order by pos <-> (select pt from search)) as rn
    from pubnames
order by pos <-> (select pt from search)
   limit 10
),
bbox as (
  select least(min((pos)[0]), min((select (pt)[0] from search))) - 0.003 as x0,
         greatest(max((pos)[0]), max((select (pt)[0] from search))) + 0.003 as x1,
         least(min((pos)[1]), min((select (pt)[1] from search))) - 0.002 as y0,
         greatest(max((pos)[1]), max((select (pt)[1] from search))) + 0.002 as y1
    from nearest
),
proj as (
  -- project lon/lat degrees onto a plain ~800-unit canvas before drawing
  -- anything, so every SVG number (stroke-width, radius, font-size) is an
  -- ordinary integer instead of a sub-0.001 fraction — some renderers don't
  -- reliably handle attribute values at that scale.
  select x0, y0, x1, y1, 800.0 / greatest(x1 - x0, y1 - y0) as scale
    from bbox
),
win as (
  select st_makeenvelope(x0, y0, x1, y1, 4326) as env from bbox
),
roads as (
  -- OSM roads around Holborn, clipped to the viewing window and projected
  select st_transscale(st_intersection(r.geom, win.env),
                        -proj.x0, -proj.y0, proj.scale, proj.scale) as geom
    from osm_london.roads r, win, proj
   where st_intersects(r.geom, win.env)
),
layers as (
  select 1 as z, '<path d="' || st_assvg(geom, 0, 1) ||
         '" fill="none" stroke="#C0B8AE" stroke-width="2"/>' as elem
    from roads
  union all
  select 2, '<circle cx="' || (((pt)[0]-proj.x0)*proj.scale)::text || '" cy="' ||
         (-(((pt)[1]-proj.y0)*proj.scale))::text ||
         '" r="9" fill="#B04020" stroke="#F2EFE9" stroke-width="2"/>' as elem
    from search, proj
  union all
  select 3,
         '<circle cx="' || (((pos)[0]-proj.x0)*proj.scale)::text || '" cy="' ||
         (-(((pos)[1]-proj.y0)*proj.scale))::text ||
         '" r="6" fill="#5B8DB8" stroke="#F2EFE9" stroke-width="1.5"/>' ||
         '<text x="' || (((pos)[0]-proj.x0)*proj.scale + 9)::text || '" y="' ||
         (-(((pos)[1]-proj.y0)*proj.scale) + (case when rn % 2 = 0 then 9 else -4 end))::text ||
         '" font-size="13" fill="#2C2820">' ||
         replace(replace(name, '&', '&amp;'), '<', '&lt;') || '</text>' as elem
    from nearest, proj
)
  select '<svg viewBox="0 ' || (-((proj.y1-proj.y0)*proj.scale)) || ' ' ||
         ((proj.x1-proj.x0)*proj.scale) || ' ' || ((proj.y1-proj.y0)*proj.scale) ||
         '" xmlns="http://www.w3.org/2000/svg">' ||
         '<rect x="0" y="' || (-((proj.y1-proj.y0)*proj.scale)) || '" width="' ||
         ((proj.x1-proj.x0)*proj.scale) || '" height="' || ((proj.y1-proj.y0)*proj.scale) ||
         '" fill="#F2EFE9"/>' ||
         string_agg(layers.elem, '' order by layers.z) || '</svg>' as svg
    from layers, proj
   group by proj.x0, proj.y0, proj.x1, proj.y1, proj.scale;
```

## Make it fast

On 28,000 pubs that query already runs in a few milliseconds, but a sequential
scan still sorts *every* pub by distance. A **GiST** index makes the database
walk straight toward the search point instead:

```sql
create index on pubnames using gist(pos);
```

With the index in place, the same `order by ... <-> ... limit` becomes an
*index scan* — PostgreSQL descends the index's bounding boxes toward the query
point and stops as soon as it has the ten nearest, touching only a handful of
pages. `EXPLAIN (analyze)` shows the `Index Scan using pubnames_pos_idx` with an
`Order By: (pos <-> '...')` and an execution time in the tens of microseconds.

This is *k-nearest-neighbour* search, built into the database: no extra service,
no precomputed distances, just an operator and an index.

> This example is drawn from Chapters of *The Art of PostgreSQL* on the
> `earthdistance` extension and geolocation.
