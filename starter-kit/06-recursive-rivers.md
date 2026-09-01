# WITH RECURSIVE: Walking a River Network

Some questions can't be answered by a single pass over a table — they need a
query that refers back to *its own output* and keeps going until there's
nothing left to add. SQL spells that `with recursive`, and a river network is
the perfect place to see why.

We use the **HydroRIVERS** dataset (loaded with `taop hydrorivers`), clipped to
France. Every reach of every river is one row, and the key column is
`next_down`: the id of the reach this one flows *into* (or `0` at the sea).
That single column turns the table into a tree.

```sql
\d hydrorivers.rivers
```

```
   Column   |   Type   | description
------------+----------+--------------------------------------------
 hyriv_id   | bigint   | this reach
 next_down  | bigint   | the reach it flows into (0 = reaches the sea)
 main_riv   | bigint   | the basin's outlet reach (its "name")
 ord_stra   | integer  | Strahler stream order
 geom       | geometry | the reach, a line
```

## The Problem

We want **every reach that drains into the Loire** — the whole basin, from the
mouth at Saint-Nazaire up to the smallest headwater stream. How do we follow
`next_down` backwards, all the way up?

## Start with what you can see

The `main_riv` column labels every reach with its basin's outlet id, and
`ord_stra` is the Strahler stream order — higher means larger. A flat query
gets us the main channels straight away:

```sql
select hyriv_id, geom, ord_stra
  from hydrorivers.rivers
 where main_riv = 20446779   -- the Loire basin
   and ord_stra >= 6;        -- trunk and major tributaries only
```

That gives 155 reaches — the Loire trunk and its biggest branches.

Every query in this page is shown twice: the plain version above returns
rows you'd read in `psql` — a `geom` column of raw WKB is not something a
terminal renders. The second version below is the *same* query with a
PostGIS tail bolted on: it wraps the same reaches in `ST_AsSVG()`, adds a
background pulled straight from `naturalearth.countries` — clipped to a
square window around the basin so France's neighbors show up too, borders and
all — and hands back one row containing one finished `<svg>...</svg>`
document. Run it and switch to the **Map** tab on its output:

```sql
with mainstem as (
  select hyriv_id, geom, ord_stra
    from hydrorivers.rivers
   where main_riv = 20446779   -- the Loire basin
     and ord_stra >= 6         -- trunk and major tributaries only
),
loire_bbox as (
  select st_xmin(bbox) as x0, st_xmax(bbox) as x1,
         st_ymin(bbox) as y0, st_ymax(bbox) as y1
    from (select st_extent(geom) as bbox
            from hydrorivers.rivers
           where main_riv = 20446779) e
),
win as (
  -- a square viewing window centered on the basin, padded out far enough
  -- that neighboring countries have a chance to show up alongside France
  select st_makeenvelope(
           (x0+x1)/2 - half, (y0+y1)/2 - half,
           (x0+x1)/2 + half, (y0+y1)/2 + half,
           4326) as env
    from loire_bbox,
         lateral (select greatest(x1-x0, y1-y0)/2 + 2.0 as half) h
),
countries as (
  -- real country borders straight from naturalearth.countries, clipped to
  -- the viewing window so whatever fits in the square gets drawn
  select c.name,
         st_intersection(c.geom, win.env) as geom
    from naturalearth.countries c, win
   where st_intersects(c.geom, win.env)
),
layers as (
  select 1 as z, '<path d="' || st_assvg(geom, 0, 3) || '" fill="' ||
         (case when name = 'France' then '#F2EFE9' else '#ECECEC' end) ||
         '" stroke="#C0B8AE" stroke-width="0.02"/>' as elem
    from countries
  union all
  select 2, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#5B8DB8" stroke-width="0.05" stroke-linecap="round"/>' as elem
    from mainstem
)
  -- ST_AsSVG negates Y for us (SVG grows downward, latitude grows north),
  -- so the viewBox's y origin is -ymax, not -ymin.
  select '<svg viewBox="' || w.x0 || ' ' || (-w.y1) || ' ' ||
         (w.x1 - w.x0) || ' ' || (w.y1 - w.y0) ||
         '" xmlns="http://www.w3.org/2000/svg">' ||
         '<rect x="' || w.x0 || '" y="' || (-w.y1) || '" width="' ||
                (w.x1 - w.x0) || '" height="' || (w.y1 - w.y0) ||
                '" fill="#E8EEF5"/>' ||
         string_agg(layers.elem, '' order by layers.z) || '</svg>' as svg
    from layers,
         (select st_xmin(env) as x0, st_xmax(env) as x1,
                 st_ymin(env) as y0, st_ymax(env) as y1
            from win) as w
   group by w.x0, w.x1, w.y0, w.y1;
```

But we had to guess the threshold, and we still have no idea which smaller
streams feed those channels. The connectivity lives in `next_down`.

## Building up manually, ring by ring

We can use the mainstem as a seed and add one ring of confluents at a time.
**Ring 1** — every reach whose `next_down` lands on a mainstem channel:

```sql
with mainstem as (
  select hyriv_id, geom, ord_stra
    from hydrorivers.rivers
   where main_riv = 20446779 and ord_stra >= 6
)
  select geom, ord_stra from mainstem          -- 155 high-order channels

union all

  select r.geom, r.ord_stra
    from hydrorivers.rivers r
    join mainstem m on r.next_down = m.hyriv_id
   where r.main_riv = 20446779
     and r.ord_stra < 6;                       -- 161 direct tributaries
```

316 reaches total — the first tributaries appearing at every confluence.

Same duplication as before — plain rows above, a complete SVG document below,
same country-borders backdrop, ring 1 drawn in a lighter blue on top of the
mainstem:

```sql
with mainstem as (
  select hyriv_id, geom, ord_stra
    from hydrorivers.rivers
   where main_riv = 20446779 and ord_stra >= 6
),
ring1 as (
  select r.hyriv_id, r.geom, r.ord_stra
    from hydrorivers.rivers r
    join mainstem m on r.next_down = m.hyriv_id
   where r.main_riv = 20446779
     and r.ord_stra < 6
),
loire_bbox as (
  select st_xmin(bbox) as x0, st_xmax(bbox) as x1,
         st_ymin(bbox) as y0, st_ymax(bbox) as y1
    from (select st_extent(geom) as bbox
            from hydrorivers.rivers
           where main_riv = 20446779) e
),
win as (
  select st_makeenvelope(
           (x0+x1)/2 - half, (y0+y1)/2 - half,
           (x0+x1)/2 + half, (y0+y1)/2 + half,
           4326) as env
    from loire_bbox,
         lateral (select greatest(x1-x0, y1-y0)/2 + 2.0 as half) h
),
countries as (
  select c.name,
         st_intersection(c.geom, win.env) as geom
    from naturalearth.countries c, win
   where st_intersects(c.geom, win.env)
),
layers as (
  select 1 as z, '<path d="' || st_assvg(geom, 0, 3) || '" fill="' ||
         (case when name = 'France' then '#F2EFE9' else '#ECECEC' end) ||
         '" stroke="#C0B8AE" stroke-width="0.02"/>' as elem
    from countries
  union all
  select 2, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#5B8DB8" stroke-width="0.05" stroke-linecap="round"/>' as elem
    from mainstem
  union all
  select 3, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#7FA5C7" stroke-width="0.02" stroke-linecap="round"/>' as elem
    from ring1
)
  select '<svg viewBox="' || w.x0 || ' ' || (-w.y1) || ' ' ||
         (w.x1 - w.x0) || ' ' || (w.y1 - w.y0) ||
         '" xmlns="http://www.w3.org/2000/svg">' ||
         '<rect x="' || w.x0 || '" y="' || (-w.y1) || '" width="' ||
                (w.x1 - w.x0) || '" height="' || (w.y1 - w.y0) ||
                '" fill="#E8EEF5"/>' ||
         string_agg(layers.elem, '' order by layers.z) || '</svg>' as svg
    from layers,
         (select st_xmin(env) as x0, st_xmax(env) as x1,
                 st_ymin(env) as y0, st_ymax(env) as y1
            from win) as w
   group by w.x0, w.x1, w.y0, w.y1;
```

**Ring 2** — name the first ring and repeat: add every reach that flows into
a ring-1 channel:

```sql
with mainstem as (
  select hyriv_id, geom, ord_stra
    from hydrorivers.rivers
   where main_riv = 20446779 and ord_stra >= 6
),
ring1 as (
  select r.hyriv_id, r.geom, r.ord_stra
    from hydrorivers.rivers r
    join mainstem m on r.next_down = m.hyriv_id
   where r.main_riv = 20446779 and r.ord_stra < 6
)
  select geom, ord_stra from mainstem
union all
  select geom, ord_stra from ring1             -- 161 direct tributaries
union all
  select r.geom, r.ord_stra
    from hydrorivers.rivers r
    join ring1 on r.next_down = ring1.hyriv_id
   where r.main_riv = 20446779;               -- 132 more: total 448
```

448 reaches — and the pattern is clear: every additional ring requires a new
CTE and a new join.

One more ring added to the SVG version, one more shade of blue:

```sql
with mainstem as (
  select hyriv_id, geom, ord_stra
    from hydrorivers.rivers
   where main_riv = 20446779 and ord_stra >= 6
),
ring1 as (
  select r.hyriv_id, r.geom, r.ord_stra
    from hydrorivers.rivers r
    join mainstem m on r.next_down = m.hyriv_id
   where r.main_riv = 20446779 and r.ord_stra < 6
),
ring2 as (
  select r.hyriv_id, r.geom, r.ord_stra
    from hydrorivers.rivers r
    join ring1 on r.next_down = ring1.hyriv_id
   where r.main_riv = 20446779
),
loire_bbox as (
  select st_xmin(bbox) as x0, st_xmax(bbox) as x1,
         st_ymin(bbox) as y0, st_ymax(bbox) as y1
    from (select st_extent(geom) as bbox
            from hydrorivers.rivers
           where main_riv = 20446779) e
),
win as (
  select st_makeenvelope(
           (x0+x1)/2 - half, (y0+y1)/2 - half,
           (x0+x1)/2 + half, (y0+y1)/2 + half,
           4326) as env
    from loire_bbox,
         lateral (select greatest(x1-x0, y1-y0)/2 + 2.0 as half) h
),
countries as (
  select c.name,
         st_intersection(c.geom, win.env) as geom
    from naturalearth.countries c, win
   where st_intersects(c.geom, win.env)
),
layers as (
  select 1 as z, '<path d="' || st_assvg(geom, 0, 3) || '" fill="' ||
         (case when name = 'France' then '#F2EFE9' else '#ECECEC' end) ||
         '" stroke="#C0B8AE" stroke-width="0.02"/>' as elem
    from countries
  union all
  select 2, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#5B8DB8" stroke-width="0.05" stroke-linecap="round"/>' as elem
    from mainstem
  union all
  select 3, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#7FA5C7" stroke-width="0.02" stroke-linecap="round"/>' as elem
    from ring1
  union all
  select 4, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#A3BDD6" stroke-width="0.012" stroke-linecap="round"/>' as elem
    from ring2
)
  select '<svg viewBox="' || w.x0 || ' ' || (-w.y1) || ' ' ||
         (w.x1 - w.x0) || ' ' || (w.y1 - w.y0) ||
         '" xmlns="http://www.w3.org/2000/svg">' ||
         '<rect x="' || w.x0 || '" y="' || (-w.y1) || '" width="' ||
                (w.x1 - w.x0) || '" height="' || (w.y1 - w.y0) ||
                '" fill="#E8EEF5"/>' ||
         string_agg(layers.elem, '' order by layers.z) || '</svg>' as svg
    from layers,
         (select st_xmin(env) as x0, st_xmax(env) as x1,
                 st_ymin(env) as y0, st_ymax(env) as y1
            from win) as w
   group by w.x0, w.x1, w.y0, w.y1;
```

The Loire basin has **6,297 reaches**. We are not writing 6,297 CTEs. The
number of rings isn't even known ahead of time. This is exactly what
recursion is for.

## The Query

A `with recursive` CTE does this automatically — it keeps adding rings until
a round adds nothing new:

```sql
with recursive loire as (

       select hyriv_id, geom, ord_stra            -- base case
         from hydrorivers.rivers
        where hyriv_id = 20446779                  --   the outlet

    union all

       select r.hyriv_id, r.geom, r.ord_stra       -- recursive term
         from hydrorivers.rivers as r
              join loire on r.next_down = loire.hyriv_id
)
select count(*) from loire;
```

```
 count
-------
  6297
```

Every reach of the basin, gathered in one query — and we never named a single
tributary.

And the SVG version of the same `with recursive` query — no ring-counting,
same country-borders backdrop, all 6,297 reaches drawn in one pass:

```sql
with recursive loire as (

       select hyriv_id, geom, ord_stra            -- base case
         from hydrorivers.rivers
        where hyriv_id = 20446779                  --   the outlet

    union all

       select r.hyriv_id, r.geom, r.ord_stra       -- recursive term
         from hydrorivers.rivers as r
              join loire on r.next_down = loire.hyriv_id
),
loire_bbox as (
  select st_xmin(bbox) as x0, st_xmax(bbox) as x1,
         st_ymin(bbox) as y0, st_ymax(bbox) as y1
    from (select st_extent(geom) as bbox
            from hydrorivers.rivers
           where main_riv = 20446779) e
),
win as (
  select st_makeenvelope(
           (x0+x1)/2 - half, (y0+y1)/2 - half,
           (x0+x1)/2 + half, (y0+y1)/2 + half,
           4326) as env
    from loire_bbox,
         lateral (select greatest(x1-x0, y1-y0)/2 + 2.0 as half) h
),
countries as (
  select c.name,
         st_intersection(c.geom, win.env) as geom
    from naturalearth.countries c, win
   where st_intersects(c.geom, win.env)
),
layers as (
  select 1 as z, '<path d="' || st_assvg(geom, 0, 3) || '" fill="' ||
         (case when name = 'France' then '#F2EFE9' else '#ECECEC' end) ||
         '" stroke="#C0B8AE" stroke-width="0.02"/>' as elem
    from countries
  union all
  select 2, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#5B8DB8" stroke-width="' ||
         (0.008 * ord_stra)::text || '" stroke-linecap="round"/>' as elem
    from loire
)
  select '<svg viewBox="' || w.x0 || ' ' || (-w.y1) || ' ' ||
         (w.x1 - w.x0) || ' ' || (w.y1 - w.y0) ||
         '" xmlns="http://www.w3.org/2000/svg">' ||
         '<rect x="' || w.x0 || '" y="' || (-w.y1) || '" width="' ||
                (w.x1 - w.x0) || '" height="' || (w.y1 - w.y0) ||
                '" fill="#E8EEF5"/>' ||
         string_agg(layers.elem, '' order by layers.z) || '</svg>' as svg
    from layers,
         (select st_xmin(env) as x0, st_xmax(env) as x1,
                 st_ymin(env) as y0, st_ymax(env) as y1
            from win) as w
   group by w.x0, w.x1, w.y0, w.y1;
```

## How it works

A `with recursive` CTE always has the same two-part shape, joined by `union all`:

1. The **base case** (the first `select`) seeds the result — here, the single
   outlet reach.
2. The **recursive term** (the second `select`) refers back to the CTE by name
   (`loire`) and produces more rows from the ones found so far. PostgreSQL runs
   it again and again, each round seeing only the rows the previous round added,
   and stops when a round adds nothing.

The join `on r.next_down = loire.hyriv_id` is what walks the tree: *give me
every reach that flows into a reach I already have.* Flip it to
`on r.hyriv_id = loire.next_down` and the same query traces a single reach the
other way — *downstream* to the sea.

The same pattern handles any hierarchy or graph stored as a parent reference: an
org chart, a threaded comment section, a bill of materials, a category tree — or
a river and all its tributaries.

> This example is drawn from Chapter 16 of [*The Art of PostgreSQL*](https://theartofpostgresql.com/book/contents/?utm_source=lab&utm_medium=app&utm_content=starterkit-06-recursive-rivers), **Group By,
> Having, With, Union All**.
