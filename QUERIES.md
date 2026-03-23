# SQL Query Discovery Guide

This guide helps you navigate the SQL queries in this repository by
**concept** and **dataset**. All queries use data loaded via the `taop`
tooling.

---

## Concepts

### Window Functions

Window functions perform calculations across rows related to the current
row, like running totals and rankings.

- `queries/04-sql-select/18-window-functions/01_01.sql`
  Demonstrates basic `OVER()` with `array_agg` to show cumulative aggregation.

- `queries/04-sql-select/18-window-functions/01_02.sql`
  Running totals using `SUM() OVER()` with ORDER BY.

- `queries/04-sql-select/18-window-functions/01_03.sql`
  `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()` for different ranking behaviors.

- `queries/04-sql-select/18-window-functions/01_04.sql`
  Frame clauses: `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

- `queries/04-sql-select/18-window-functions/02_01.sql`
  Partition-specific frames with `PARTITION BY` to reset calculations per group.

- `queries/04-sql-select/18-window-functions/03_01.sql`
  `FIRST_VALUE()`, `LAST_VALUE()`, `NTH_VALUE()` to access values anywhere in a window.

### Aggregations

- `queries/04-sql-select/16-sql-103/01_01.sql`
  Basic `GROUP BY` aggregation with `SUM()`.

- `queries/04-sql-select/16-sql-103/01_02_f1db.decade.races.sql`
  Aggregates races grouped by decade using F1 data.

- `queries/04-sql-select/16-sql-103/02_01.sql`
  Aggregates without `GROUP BY` returns a single-row result.

- `queries/04-sql-select/16-sql-103/03_01.sql`
  `HAVING` clause filters groups after aggregation.

- `queries/04-sql-select/16-sql-103/04_01.sql`
  `GROUPING SETS()` computes multiple aggregations in one query.

- `queries/04-sql-select/16-sql-103/04_02.sql`
  `CUBE()` generates all possible combinations of grouping sets.

- `queries/04-sql-select/16-sql-103/04_03.sql`
  `ROLLUP()` creates hierarchical subtotals.

- `queries/05-data-types/23-pg-data-types-101/13_01_rates.sql`
  `daterange` type with window functions to manage currency rate validity periods.

### Common Table Expressions (CTE)

CTEs simplify complex queries by creating temporary named result sets.

- `queries/04-sql-select/16-sql-103/05_01.sql`
  Basic `WITH` query (CTE) to organize complex logic.

- `queries/04-sql-select/16-sql-103/05_02_f1db.accidents.sql`
  CTE with F1 accident data to find incident-prone drivers.

- `queries/04-sql-select/16-sql-103/05_03_f1db.seasons.winners.sql`
  Recursive CTE for F1 season analysis, traversing race results.

### DISTINCT ON

- `queries/04-sql-select/16-sql-103/06_01.sql`
  `DISTINCT ON` retrieves the first row per group without subqueries.

- `queries/04-sql-select/16-sql-103/06_02.sql`
  `DISTINCT ON` with multiple columns for complex deduplication.

- `queries/04-sql-select/16-sql-103/06_03.sql`
  Combining `DISTINCT ON` with ordering for flexible results.

### kNN / Distance Ordering

Find nearest neighbors using PostgreSQL's geometric operators.

- `queries/04-sql-select/15-sql-102/02_01.sql`
  Nearest circuits to Paris using the `<->` distance operator.

- `queries/04-sql-select/15-sql-102/02_02.sql`
  Optimized nearest circuits using GiST index.

- `queries/04-sql-select/15-sql-102/02_03.sql`
  Ordering by distance from any point coordinate.

### Trigrams / Fuzzy Text Search

The `pg_trgm` extension enables fuzzy matching by splitting text into
3-character sequences.

- `queries/08-extensions/46-trigrams/01_01.sql`
  Enable the `pg_trgm` extension.

- `queries/08-extensions/46-trigrams/02_01.sql`
  Shows trigram extraction and the `similarity()` function.

- `queries/08-extensions/46-trigrams/02_02.sql`
  Comparing similarity scores between search terms.

- `queries/08-extensions/46-trigrams/02_03.sql`
  Creates a GIN index for fast trigram search.

- `queries/08-extensions/46-trigrams/02_04.sql`
  Combines `ILIKE` with trigram index for fuzzy pattern matching.

- `queries/08-extensions/46-trigrams/03_01.sql`
  Autocomplete suggestions using trigram similarity.

- `queries/08-extensions/46-trigrams/03_02.sql`
  Fuzzy matching on song titles from LastFM data.

- `queries/08-extensions/46-trigrams/04_01.sql`
  Comparing GiST vs GIN trigram index performance.

- `queries/08-extensions/46-trigrams/04_02.sql`
  Trigram index performance tuning and maintenance.

### Earth Distance

Calculate distances between points on Earth's surface.

- `queries/08-extensions/49-earthdistance/01_01.sql`
  Enable `earthdistance` and `cube` extensions.

- `queries/08-extensions/49-earthdistance/01_02.sql`
  Earth's distance calculation between two points.

- `queries/08-extensions/49-earthdistance/02_01.sql`
  Distance between UK cities in miles.

- `queries/08-extensions/49-earthdistance/02_02.sql`
  Find pubs within a given radius.

- `queries/08-extensions/49-earthdistance/03_01.sql`
  Group by city and calculate average distances.

### Geolocation (IP-based)

IP geolocation enables finding user locations from IP addresses.

- `queries/08-extensions/50-geolocation-ip4r/01_01_geolite.sql`
  Enable `ip4r` extension and load GeoLite data.

- `queries/08-extensions/50-geolocation-ip4r/02_01.sql`
  Basic IP range lookup using `>>=` operator.

- `queries/08-extensions/50-geolocation-ip4r/02_02.sql`
  Binary search on IP ranges for performance.

- `queries/08-extensions/50-geolocation-ip4r/03_01.sql`
  City lookup by IP address with join to location data.

- `queries/08-extensions/50-geolocation-ip4r/04_01.sql`
  Emergency pub finder: geolocation combined with distance search.

### HyperLogLog (Distinct Counting)

HyperLogLog provides memory-efficient approximate distinct counting.

- `queries/08-extensions/51-hyperloglog/01_01.sql`
  Enable the `hll` extension.

- `queries/08-extensions/51-hyperloglog/03_01_tweets.visitor.sql`
  Count distinct tweet visitors efficiently.

- `queries/08-extensions/51-hyperloglog/05_01_tweets.hll.sql`
  HLL aggregation for tweet visit counts.

- `queries/08-extensions/51-hyperloglog/06_01_tweets.update.proc.sql`
  Scheduled HLL computation with stored procedures.

### Pub Names / k-NN Search

- `queries/08-extensions/48-pub-names-knn/01_01.sql`
  Pub names schema with PostgreSQL `point` type for coordinates.

- `queries/08-extensions/48-pub-names-knn/03_01.sql`
  Find nearest pub to London coordinates using `<->`.

- `queries/08-extensions/48-pub-names-knn/04_01.sql`
  kNN search optimized with spatial index.

- `queries/08-extensions/48-pub-names-knn/04_02.sql`
  Further optimization techniques for kNN queries.

### NULL Handling

Understanding NULL is essential for correct SQL behavior.

- `queries/04-sql-select/17-nulls/01_01.sql`
  Three-valued logic: TRUE, FALSE, and UNKNOWN.

- `queries/04-sql-select/17-nulls/01_02.sql`
  NULL comparisons with `IS NULL` / `IS NOT NULL`.

- `queries/04-sql-select/17-nulls/02_01.sql`
  `NOT NULL` constraint behavior and implications.

- `queries/04-sql-select/17-nulls/03_01.sql`
  Outer joins that introduce NULLs into results.

- `queries/04-sql-select/17-nulls/04_01.sql`
  `COALESCE()` provides default values for NULLs.

### JSON / Arrays

PostgreSQL supports rich non-relational data types.

- `queries/05-data-types/24-non-relational-types/01_01_tweets.sql`
  Tweet schema with denormalized array columns.

- `queries/05-data-types/24-non-relational-types/01_03_hashtag.sql`
  Extracting and unnesting hashtags from tweet arrays.

- `queries/05-data-types/24-non-relational-types/01_06.sql`
  Array operations: `ARRAY[]`, `unnest()`, and array slicing.

- `queries/05-data-types/24-non-relational-types/04_01.sql`
  JSON and JSONB types for semi-structured data.

- `queries/05-data-types/24-non-relational-types/04_03.sql`
  JSON operators: `->` for objects, `->>` for text extraction.

- `queries/05-data-types/24-non-relational-types/04_04.sql`
  JSON indexing with GIN for fast JSON queries.

### Data Modeling / EAV

- `queries/06-data-modeling/31-anti-patterns/01_01_eav.create.params.sql`
  EAV (Entity-Attribute-Value) pattern for flexible schemas.

- `queries/06-data-modeling/31-anti-patterns/01_03_eav.support.sql`
  Querying EAV schema with dynamic parameters.

- `queries/06-data-modeling/31-anti-patterns/06_01.sql`
  Surrogate keys vs natural keys.

- `queries/06-data-modeling/29-normalisation/09_01.sql`
  Check constraints for data validation.

### Joins and Relations

- `queries/04-sql-select/14-sql-101/04_01.sql`
  Basic `INNER JOIN` syntax and usage.

- `queries/04-sql-select/14-sql-101/04_02.sql`
  Chaining multiple joins across tables.

- `queries/04-sql-select/19-relations/01_01.sql`
  Understanding relations and table relationships.

- `queries/04-sql-select/19-relations/02_01.sql`
  LEFT, RIGHT, and FULL outer joins.

### Materialized Views

Materialized views store query results for fast access.

- `queries/06-data-modeling/32-denormalisation/04_01.sql`
  Basic materialized view creation.

- `queries/06-data-modeling/32-denormalisation/04_02_f1db.points.mv.sql`
  Pre-computed F1 driver standings materialized view.

- `queries/06-data-modeling/32-denormalisation/04_04.sql`
  `REFRESH MATERIALIZED VIEW` syntax.

### MoMA / Batch Updates

- `queries/07-concurrency/41-moma/01_artists.sql`
  MoMA artists schema for batch operations.

- `queries/07-concurrency/41-moma/02.sql`
  Batch update patterns for efficient data loading.

- `queries/07-concurrency/41-moma/03_01.diff`
  `ON CONFLICT DO NOTHING` for idempotent inserts.

---

## Datasets

### Tweet (Shakespeare tweets)

**Load:** `docker compose run --rm taop tweet`

Tweets enriched with Shakespeare play data. Great for arrays, aggregations,
and HyperLogLog.

- Arrays: `queries/05-data-types/24-non-relational-types/01_*.sql`
- HyperLogLog: `queries/08-extensions/51-hyperloglog/03_01_tweets.visitor.sql`, `05_01_tweets.hll.sql`
- Concurrency: `queries/07-concurrency/35-practical-intro/01_tweets.sql`, `02_tweets.norm.1.sql`, `03_tweets.norm.2.sql`

### F1DB (Formula 1 Database)

**Load:** `docker compose run --rm taop f1db`

Complete F1 racing data including drivers, races, results, and constructors.

- GROUP BY: `queries/04-sql-select/16-sql-103/01_02_f1db.decade.races.sql`, `05_02_f1db.accidents.sql`
- CTE: `queries/04-sql-select/16-sql-103/05_03_f1db.seasons.winners.sql`
- Materialized Views: `queries/06-data-modeling/32-denormalisation/04_02_f1db.points.mv.sql`
- Set Operations: `queries/04-sql-select/16-sql-103/07_01_f1db.standinds.union.sql`, `07_02_f1db.standinds.except.sql`

### Rates (Currency Exchange Rates)

**Load:** `docker compose run --rm taop rates`

IMF exchange rates with date range validity periods.

- Date Ranges: `queries/05-data-types/23-pg-data-types-101/13_01_rates.sql`
- Exclusion Constraints: `queries/05-data-types/23-pg-data-types-101/13_03.sql`

### Magic (Magic: The Gathering)

**Load:** `docker compose run --rm taop magic`

Card data stored as JSON for schemaless design exploration.

- JSON/JSONB: `queries/06-data-modeling/33-not-only-sql/01_01_magic.sql`, `01_03_magic.cards.sql`
- NoSQL patterns: `queries/06-data-modeling/33-not-only-sql/01_04.sql`

### MoMA (Museum of Modern Art)

**Load:** `docker compose run --rm taop moma`

Art collection data for batch update and concurrency examples.

- Batch Updates: `queries/07-concurrency/41-moma/01_artists.sql`, `02.sql`
- Concurrency: `queries/07-concurrency/41-moma/02_01.sql`, `03_01.diff`

### Pubnames (UK Pub Names)

**Load:** `docker compose run --rm taop pubnames`

UK pub locations with coordinates for k-NN and distance queries.

- kNN Search: `queries/08-extensions/48-pub-names-knn/03_01.sql`, `04_01.sql`, `04_02.sql`
- Point Geometry: `queries/08-extensions/48-pub-names-knn/01_01.sql`

### GeoLite (IP Geolocation)

**Load:** `docker compose run --rm taop geolite` 

Note: manual download required with a personal licence key obtained from the
Maxmind provider.

MaxMind GeoLite2 IP geolocation data.

- IP Range Lookup: `queries/08-extensions/50-geolocation-ip4r/02_01.sql`, `02_02.sql`
- City Lookup: `queries/08-extensions/50-geolocation-ip4r/03_01.sql`
- Emergency Pubs: `queries/08-extensions/50-geolocation-ip4r/04_01.sql`, `04_02.sql`

### Commitlog (Git History)

**Load:** `docker compose run --rm taop commitlog`

PostgreSQL and pgloader git commit history for analytics.
