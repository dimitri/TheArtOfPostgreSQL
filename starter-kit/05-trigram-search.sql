# Fuzzy Text Search: Trigram Similarity

PostgreSQL's `pg_trgm` extension enables sub-millisecond fuzzy matching and typo tolerance. The `%>` operator checks similarity, `<->` gives a distance score.

## The Problem

Find tracks where the title is similar to "peas" (handles typos like "peace", "please") with results ranked by similarity.

## The Query

```sql
explain (analyze, costs off)
   select artist, title
     from lastfm.track
   where title %> 'peas'
 order by title <-> 'peas'
    limit 5;
```

## Step-by-Step

### Step 1: Exact Match

Start with a simple LIKE:

```sql
select artist, title
  from lastfm.track
 where title like '%peas%';
```

### Step 2: Enable pg_trgm Extension

Create the extension to unlock trigram operators:

```sql
create extension if not exists pg_trgm;
```

### Step 3: Use Similarity Operator

Use `%>` for similarity matching:

```sql
select artist, title
  from lastfm.track
 where title %> 'peas';
```

### Step 4: Rank by Similarity

Use `<->` (distance) to order by similarity:

```sql
select artist, title,
       similarity(title, 'peas') as sim
  from lastfm.track
 where title %> 'peas'
 order by title <-> 'peas'
 limit 5;
```

### Step 5: Add GIN Index

Create a GIN index for fast trigram searches:

```sql
create index on lastfm.track using gin(title gin_trgm_ops);

-- Now the query is sub-millisecond!
```

## Key Concepts

- `pg_trgm` extension - Trigram-based text similarity
- `%>` operator - "Is similar to"
- `<->` operator - Similarity distance (lower = more similar)
- `GIN index` - Inverted index for fast trigram lookups
- `similarity()` function - Returns 0-1 similarity score

## How to Run

```bash
docker compose run --rm -it psql

-- Enable the extension
create extension if not exists pg_trgm;

-- Create index for performance
create index on lastfm.track using gin(title gin_trgm_ops);

-- Run the query
\i starter-kit/05-trigram-search.sql
```

## Try These Variations

```sql
-- Find artists similar to "coldplay"
select artist, title from lastfm.track
 where artist %> 'coldplay'
 order by artist <-> 'coldplay'
 limit 5;

-- Find titles with 3+ character match
select title from lastfm.track
 where title % 'music'
 limit 10;
```
