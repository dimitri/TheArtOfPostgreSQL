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

# Query data
docker compose run --rm -it psql
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
