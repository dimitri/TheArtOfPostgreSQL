# PostgreSQL Starter Kit

This repository contains hundreds of queries, but not all of them are equal
when you’re getting started. Some patterns fundamentally change how you
think about SQL—replacing application code, simplifying complex logic, or
unlocking performance gains.

This directory contains 3 hand-picked SQL queries that demonstrate some of
PostgreSQL's powerful features that are not widely used and known, despite
being very useful in important use-cases.

## The Queries

1. **Nested LATERAL Joins** - Top-N queries per group, nested
2. **GROUPING SETS + FILTER** - Multiple aggregations in one query
3. **percentile_cont()** - Calculate multiple percentiles at once

## How to Use

Start by loading the datasets, then explore the queries in order. Each query
builds on concepts from the previous one.

### Load the Data

First, load the required datasets:

```bash
# Build Docker images
docker compose build

# Start PostgreSQL
docker compose up -d postgres

# Load all datasets
docker compose run --rm taop load-data
```

### Run a Query

```bash
# Start psql
docker compose run --rm -it psql

# View a query
\! cat 06-data-modeling/28-repl/03_03_topn-with-comments.sql

# Execute it
\i /starter-kit/01-nested-lateral.sql
```

## Learning Path

Each query file contains:
- An introduction explaining the concept
- The complete SQL query
- A step-by-step approach to build up to the final query

Read the step-by-step section first, then try to write the intermediate
queries yourself before looking at the complete solution.
