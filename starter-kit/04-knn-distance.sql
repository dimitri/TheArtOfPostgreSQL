# KNN Distance Search: Geographic Nearest-Neighbor

PostgreSQL supports native geographic distance queries with the `<->` operator. Combined with `LATERAL`, you get efficient KNN (K-Nearest Neighbors) searches.

## The Problem

For each hashtag (with location), find the nearest city/geoname and return its country, region, and district.

## The Query

```sql
select id,
       round((hashtag.location <-> geoname.location)::numeric, 3) as dist,
       country.iso,
       region.name as region,
       district.name as district
  from hashtag
       left join lateral (
          select geonameid, isocode, regcode, discode, location
            from geoname.geoname
        order by location <-> hashtag.location
           limit 1
       ) as geoname on true
       left join geoname.country using(isocode)
       left join geoname.region using(isocode, regcode)
       left join geoname.district using(isocode, regcode, discode)
 order by id
 limit 5;
```

## Step-by-Step

### Step 1: Basic Distance Calculation

Use the `<->` operator for distance between points:

```sql
select name,
       location,
       point(0, 0) <-> location as distance
  from geoname.geoname
 order by distance
 limit 5;
```

### Step 2: Add LATERAL

Use `LATERAL` to find nearest for each reference point:

```sql
select ref.id, geoname.name, geoname.location
  from reference_points as ref
  join lateral (
      select geonameid, name, location
        from geoname.geoname
    order by location <-> ref.location
       limit 1
  ) as geoname on true;
```

### Step 3: Join Geographic Hierarchy

Add joins to get country, region, district:

```sql
select ref.id,
       geoname.name,
       country.name as country,
       region.name as region
  from reference_points as ref
  join lateral (...) as geoname on true
  left join geoname.country using(isocode)
  left join geoname.region using(isocode, regcode);
```

### Step 4: Calculate Distance

Add the distance calculation:

```sql
select ref.id,
       geoname.location <-> ref.location as distance,
       country.name as country,
       region.name as region
  from reference_points as ref
  join lateral (
      select geonameid, isocode, regcode, location
        from geoname.geoname
    order by location <-> ref.location
       limit 1
  ) as geoname on true
  left join geoname.country using(isocode)
  left join geoname.region using(isocode, regcode);
```

## Key Concepts

- `<->` operator - Geometric distance between points
- `LATERAL` - Correlated subqueries that can reference outer tables
- GIST index - Makes KNN queries fast

## How to Run

```bash
docker compose run --rm -it psql

-- Load the geoname data (requires manual setup)
-- See data/geolite/README.md for instructions

-- Then run the query
\i starter-kit/04-knn-distance.sql
```
