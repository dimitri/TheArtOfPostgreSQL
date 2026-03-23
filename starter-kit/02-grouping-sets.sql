# GROUPING SETS + FILTER: Multiple Aggregations in One Pass

Ever needed to compute both per-driver and per-constructor points in the same query? PostgreSQL's `GROUPING SETS` and `FILTER` clauses make this elegant.

## The Problem

Calculate season points for both drivers AND constructors in a single aggregation pass, then find the champion for each.

## The Query

```sql
with points as (
   select year as season, driverid, constructorid,
          sum(points) as points
     from results join races using(raceid)
 group by grouping sets((year, driverid),
                        (year, constructorid))
   having sum(points) > 0
),
tops as (
   select season,
          max(points) filter(where driverid is null) as ctops,
          max(points) filter(where constructorid is null) as dtops
     from points
 group by season
),
champs as (
   select tops.season, champ_driver.driverid, champ_driver.points,
          champ_constructor.constructorid, champ_constructor.points
     from tops
          join points as champ_driver on champ_driver.season = tops.season
           and champ_driver.constructorid is null
           and champ_driver.points = tops.dtops
          join points as champ_constructor on champ_constructor.season = tops.season
           and champ_constructor.driverid is null
           and champ_constructor.points = tops.ctops
)
select season,
       format('%s %s', drivers.forename, drivers.surname) as "Driver's Champion",
       constructors.name as "Constructor's champion"
  from champs
       join drivers using(driverid)
       join constructors using(constructorid)
order by season;
```

## Step-by-Step

### Step 1: Simple GROUP BY

Start with basic points aggregation:

```sql
select year, driverid, sum(points) as pts
  from results join races using(raceid)
 group by year, driverid
 order by year, pts desc;
```

### Step 2: Add GROUPING SETS

Use `GROUPING SETS` to aggregate both drivers AND constructors in one pass:

```sql
select year as season, driverid, constructorid,
       sum(points) as pts
  from results join races using(raceid)
 group by grouping sets((year, driverid),
                        (year, constructorid))
 order by year, pts desc;
```

### Step 3: Add FILTER Clause

Use `FILTER` to extract top points for each category:

```sql
select season,
       max(points) filter(where driverid is not null) as driver_pts,
       max(points) filter(where constructorid is not null) as constructor_pts
  from (
      select year as season, driverid, constructorid, sum(points) as points
        from results join races using(raceid)
       group by grouping sets((year, driverid), (year, constructorid))
  ) as data
 group by season;
```

### Step 4: Self-Join to Find Champions

Join back to find who achieved those top scores:

```sql
-- Join the tops CTE to the points CTE twice:
-- once to find the driver, once to find the constructor
from tops
join points as champ_driver on champ_driver.season = tops.season
                     and champ_driver.constructorid is null
                     and champ_driver.points = tops.dtops
join points as champ_constructor on champ_constructor.season = tops.season
                               and champ_constructor.driverid is null
                               and champ_constructor.points = tops.ctops
```

## How to Run

```bash
docker compose run --rm -it psql

-- First load the commitlog data
\i data/commitlog/commitlog.sql
\i queries/04-sql-select/16-sql-103/00_f1db.setup.sql

-- Then run the query
\i starter-kit/02-grouping-sets.sql
```
