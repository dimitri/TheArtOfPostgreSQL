# The Art of PostgreSQL

This repository is an Open Source companion for the book [The Art of
PostgreSQL](https://theartofpostgresql.com). It is not intended as an
autonomous repository that could be used on its own, it is meant to use
while reading the book.

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

This gives the following output:

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

See [datasets.md](datasets.md) for a complete list of available datasets and how to load them.

## Environment Variables

The following environment variables configure dataset locations in the Docker container:

- `SCAN34_DIR` - scan34 access log files
- `MAGIC_DIR` - Magic: The Gathering data
- `RATES_DIR` - currency exchange rates
- `SHAKESPEARE_DIR` - Shakespeare data
- `SHAKESPEARE_PLAY_XML` - default play XML file
- `F1DB_DIR` - Ergast F1 database dump
- `COMMITLOG_DIR` - commitlog git repository data
- `MOMA_DIR` - MoMA artist data
- `OPENDATA_DIR` - Open data files
- `EAV_DIR` - EAV pattern examples
- `SANDBOX_DIR` - Sandbox test data
