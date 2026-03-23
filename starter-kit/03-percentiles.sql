# percentile_cont(): Multiple Percentiles in One Query

Need median, 90th percentile, 95th percentile, AND 99th percentile? PostgreSQL computes them all in one query with `percentile_cont()`.

## The Problem

Calculate commit time percentiles (median, 90th, 95th, 99th) for each project in one query.

## The Query

```sql
with perc_arrays as (
   select project,
          avg(cts-ats) as average,
          percentile_cont(array[0.5, 0.9, 0.95, 0.99])
             within group(order by cts-ats) as parr
     from commitlog
    where ats <> cts
 group by project
)
select project, average,
       parr[1] as median,
       parr[2] as "%90th",
       parr[3] as "%95th",
       parr[4] as "%99th"
  from perc_arrays;
```

## Step-by-Step

### Step 1: Basic Average

Start with simple average commit time:

```sql
select project, avg(cts-ats) as avg_time
  from commitlog
 where ats <> cts
 group by project;
```

### Step 2: Calculate Median

Use `percentile_cont(0.5)` with `WITHIN GROUP`:

```sql
select project,
       percentile_cont(0.5) within group(order by cts-ats) as median
  from commitlog
 where ats <> cts
 group by project;
```

### Step 3: Multiple Percentiles

Pass an array to compute multiple percentiles at once:

```sql
select project,
       percentile_cont(array[0.5, 0.9, 0.95, 0.99])
          within group(order by cts-ats) as percentiles
  from commitlog
 where ats <> cts
 group by project;
```

### Step 4: Extract Array Elements

Access individual percentiles with array indexing:

```sql
select project,
       percentiles[1] as median,
       percentiles[2] as p90,
       percentiles[3] as p95,
       percentiles[4] as p99
  from (
      select project,
             percentile_cont(array[0.5, 0.9, 0.95, 0.99])
                within group(order by cts-ats) as percentiles
        from commitlog
       where ats <> cts
       group by project
  ) as data;
```

## Key Concepts

- `percentile_cont()` - Inverse distribution function
- `WITHIN GROUP` - Apply aggregate to sorted rows
- Array input - Compute multiple values in one call

## How to Run

```bash
docker compose run --rm -it psql

-- First load the commitlog data
\i data/commitlog/commitlog.sql

-- Then run the query
\i starter-kit/03-percentiles.sql
```
