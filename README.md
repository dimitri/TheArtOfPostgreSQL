# The Art of PostgreSQL

This repository contain The PostgreSQL practice lab used with the book [The
Art of PostgreSQL](https://theartofpostgresql.com). 

Here, you can run real queries, explore realistic datasets, and observe how
PostgreSQL behaves in practice. Each example is designed to help you move
beyond theory: execute the queries, compare results, experiment with
variations, and understand performance trade-offs firsthand.

Use this lab alongside the book to turn concepts into working knowledge—and
to build an intuition for writing efficient, production-grade SQL.

The repository contains all of the SQL queries from the book, organized by
chapters, in a way that you can re-use them directly. The repository also
contains the Open Source data sets used through the book, and when needed
the scripts around the data sets that allow importing and processing them
into a Postgres database.

## Quick Start

```bash
# Build Docker images
docker compose build

# Start PostgreSQL
docker compose up -d postgres

# Load all datasets
docker compose run --rm taop load-data
```

## Starter Kit — Start Here

If you’re new to this lab, begin with the **starter kit**.

→ [`starter-kit/`](starter-kit/)

This is a **guided, hands-on learning path** built from a small set of
carefully selected queries. Instead of exploring hundreds of files, you will
focus on a few high-impact examples that demonstrate what PostgreSQL can
really do.

### What you’ll learn

The starter kit walks you through three advanced—but highly practical—SQL
patterns:

* **Nested LATERAL joins** — solve top-N per group problems cleanly
* **GROUPING SETS + FILTER** — compute multiple aggregations in a single query
* **percentile_cont()** — calculate multiple percentiles efficiently

### How to approach it

Each query is designed as a mini lab:

1. Read the problem
2. Follow the step-by-step build-up
3. Run the final query
4. Experiment with variations

Expect to spend **15–30 minutes** to complete the full starter kit.

Once you’ve completed the starter kit, you’ll have a solid foundation to
explore the rest of the repository and its full collection of queries.

If you want to go deeper into the concepts and patterns behind these
examples, see [The Art of PostgreSQL](https://theartofpostgresql.com) for
full explanations and additional material.

## Using the Queries

The `queries/` directory contains SQL examples organized by chapter. You can
view and execute them using psql. Here we see an example that uses the query
`03_01_f1db.decade.top3.sql` from Chapter 14 Order By, Limit, No Offset of
the book [The Art of PostgreSQL](https://theartofpostgresql.com).

> The following query is a classic top-N implementation. It reports for each
> decade the top three drivers in terms of race wins. It is both a classic
> top-N because it is done thanks to a lateral subquery, and at the same
> time it’s not so classic because we are joining against computed data. The
> decade information is not part of our data model, and we need to extract
> it from the `races.date` column.

```bash
# Start psql
docker compose run --rm -it psql

# View a query file
\! cat queries/04-sql-select/15-sql-102/03_01_f1db.decade.top3.sql

# Execute a query
\i queries/04-sql-select/15-sql-102/03_01_f1db.decade.top3.sql
```

The query is the following:

``` sql
with decades as
(
   select extract('year' from date_trunc('decade', date)) as decade
     from races
 group by decade
)
select decade,
       rank() over(partition by decade
                   order by wins desc)
       as rank,
       forename, surname, wins

  from decades
       left join lateral
       (
          select code, forename, surname, count(*) as wins
            from drivers

                 join results
                   on results.driverid = drivers.driverid
                  and results.position = 1

                 join races using(raceid)

           where   extract('year' from date_trunc('decade', races.date))
                 = decades.decade

        group by decades.decade, drivers.driverid
        order by wins desc
           limit 3
       )
       as winners on true

order by decade asc, wins desc;
```

And the `docker compose run --rm -it psql` with `\i ...` shows the following
result of executing the query (without having to copy paste more than the
path to the file on-disk available in the container):

```
taop@taop=# \i 04-sql-select/15-sql-102/03_01_f1db.decade.top3.sql
 decade │ rank │ forename  │  surname   │ wins 
════════╪══════╪═══════════╪════════════╪══════
   1950 │    1 │ Juan      │ Fangio     │   24
   1950 │    2 │ Alberto   │ Ascari     │   13
   1950 │    3 │ Stirling  │ Moss       │   12
   1960 │    1 │ Jim       │ Clark      │   25
   1960 │    2 │ Graham    │ Hill       │   14
   1960 │    3 │ Jackie    │ Stewart    │   11
   1970 │    1 │ Niki      │ Lauda      │   17
   1970 │    2 │ Jackie    │ Stewart    │   16
   1970 │    3 │ Emerson   │ Fittipaldi │   14
   1980 │    1 │ Alain     │ Prost      │   39
   1980 │    2 │ Ayrton    │ Senna      │   20
   1980 │    2 │ Nelson    │ Piquet     │   20
   1990 │    1 │ Michael   │ Schumacher │   35
   1990 │    2 │ Damon     │ Hill       │   22
   1990 │    3 │ Ayrton    │ Senna      │   21
   2000 │    1 │ Michael   │ Schumacher │   56
   2000 │    2 │ Fernando  │ Alonso     │   21
   2000 │    3 │ Kimi      │ Räikkönen  │   18
   2010 │    1 │ Lewis     │ Hamilton   │   46
   2010 │    2 │ Sebastian │ Vettel     │   41
   2010 │    3 │ Nico      │ Rosberg    │   23
(21 rows)
```

## Docker Setup

See [docker/README.md](docker/README.md) for detailed instructions.

## Datasets

See [datasets.md](datasets.md) for a complete list of available datasets and
how to load them.

