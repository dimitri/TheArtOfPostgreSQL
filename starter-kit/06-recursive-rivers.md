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

That gives 155 reaches — the Loire trunk and its biggest branches, spread
across the map:

![Loire main channels — flat query on stream order](img/fig-river-mainstem.png)

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

316 reaches total. You can see the first tributaries appearing at every
confluence:

![Mainstem plus one ring of confluents: 316 reaches](img/fig-river-hop1.png)

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
CTE and a new join:

![Two rings of confluents: 448 reaches out of 6,297](img/fig-river-hop2.png)

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
tributary. Plotted, it draws the whole Loire system:

![The Loire basin, gathered upstream with WITH RECURSIVE](img/fig-river-recursive.png)

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

> This example is drawn from Chapter 15 of *The Art of PostgreSQL*, **Group By,
> Having, With, Union All**.
