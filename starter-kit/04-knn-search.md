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
point in blue, the ten nearest pubs picked out and named:

![The ten nearest pubs to Holborn](img/fig-pubs-knn.png)

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
