# percentile_cont(): Multiple Percentiles in One Query

Need median, 90th percentile, 95th percentile, AND 99th percentile?
PostgreSQL computes them all in one query with `percentile_cont()`.

## The Problem

Calculate commit time percentiles (median, 90th, 95th, 99th) for each
project in one query.

## The Query

You can either load the query from disk or copy paste it in the terminal
obtained with `docker compose run --rm -it psql`:

```
\i 05-data-types/23-pg-data-types-101/11_04.sql
```

The file contains the following code:

```sql
with perc_arrays as (
   select project,
          avg(cts-ats) as average,
          percentile_cont(array[0.5, 0.9, 0.95, 0.99])
             within group(order by cts-ats) as parr
     from commits
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

This gives us the following statistics:

```
project │ postgres
average │ @ 1 day 10 hours 36 mins 56.743525 secs
median  │ @ 3 mins 46 secs
%90th   │ @ 3 hours 21 mins 57 secs
%95th   │ @ 2 days 22 hours 57 mins 3 secs
%99th   │ @ 34 days 20 hours 53 mins 12.28 secs
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

We get:

```
 project  │                avg_time                 
══════════╪═════════════════════════════════════════
 postgres │ @ 1 day 10 hours 36 mins 56.743525 secs
(1 row)
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

Using the dataset as loaded here, we then get:

```
 project  │      median      
══════════╪══════════════════
 postgres │ @ 3 mins 46 secs
(1 row)
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

This returns the data within a Postgres array:

```
 project  │                                                         percentiles                                                         
══════════╪═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
 postgres │ {"@ 3 mins 46 secs","@ 3 hours 21 mins 57 secs","@ 2 days 22 hours 57 mins 3 secs","@ 34 days 20 hours 53 mins 12.28 secs"}
(1 row)
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
