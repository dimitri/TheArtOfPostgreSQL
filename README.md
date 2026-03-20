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

A dockerfile is provided that automates most of the data build and import
and allows to quickly have an interactive terminal available from where to
play with the book SQL files.

## Docker Setup

This repository includes a Docker Compose setup for running PostgreSQL and
the taop tool.

### Build

First, build the Docker images:

```bash
docker compose build
```

### Start PostgreSQL

Run the PostgreSQL database in the background:

```bash
docker compose up -d postgres
```

### Load Data

Use the taop service to load datasets. The main datasets are loaded with a
single command:

```bash
docker compose run --rm taop load-data
```

The commitlog data is managed in a separate docker container, to load the
Postgres and pgloader commit logs use the following command:

```bash
docker compose run --rm commitlog
```

### Query Data

Use the psql service for interactive querying with all SQL queries from the
book:

```bash
docker compose run --rm -it psql
```

It is possible to discover the queries available by using psql commands `\!
ls` or `\! find .`.

The psql service includes:
- The `queries/` directory mounted at `/usr/src/taop/queries`
- The `apps/cdstore/` application at `/usr/src/taop/cdstore`
- The `data/` directory at `/data`

### Run taop Commands

The taop tool provides various commands for loading and processing data:

```bash
# Get help
docker compose run --rm taop

# Run a specific command
docker compose run --rm taop <command>
```

Environment variables for default directories:
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

### Stop Services

```bash
docker compose down
```

## Datasets

This repository includes several datasets for learning SQL with PostgreSQL:

### Shakespeare (tweet)

Twitter-like dataset using Shakespeare play characters as users. Contains
users, followers, lists, and tweets. Load with `taop tweet`.

### Magic: The Gathering (magic)

Complete card database from the Magic: The Gathering card game in JSON
format. Contains sets, cards, and card attributes. Load with `taop magic`.

### Currency Exchange Rates (rates)

IMF currency exchange rates data with daily rates for multiple currencies
over time. Includes typed tables with exclusion constraints. Load with `taop
rates`.

### Scan34 Access Logs (scan34)

Apache access log data from the scan34 web server. Contains IP addresses,
timestamps, requests, and HTTP status codes. Load with `taop scan34`.

### Pubnames

Public house names and locations from OpenStreetMap. Contains geographic
positions and names of pubs in the UK. Load with `taop pubnames`.

### Ergast F1 Database (f1db)

Formula 1 racing data from the Ergast Developer API. Contains races,
drivers, constructors, results, and seasons from 1950 to present. Load with
`taop f1db`.

### MoMA (moma)

Museum of Modern Art artist collection data. Contains artist names, biographies,
nationalities, and identifiers. Load with `taop moma`.

### Open Data (opendata)

Various open datasets including hello world translations, Archives de la Planète
photo collection, and CIA World Factbook data. Load with `taop opendata`.

### CD Store (cdstore)

Sample e-commerce application data with customers, products, orders, and
inventory.

### Git Log (commitlog)

Git commit logs from PostgreSQL and pgloader repositories. Fetch with:
```bash
taop gitlog fetch postgres
taop gitlog fetch pgloader
```
Then use `taop gitlog <csv> <project-directory>` to parse logs.

### GeoLite

MaxMind GeoLite2 geographic IP location data for geolocation queries.

### EAV (Entity-Attribute-Value)

Sample data demonstrating the Entity-Attribute-Value database design pattern with
various attributes. Load with `taop eav`.

### Sandbox

Various test data and utilities for experimenting with PostgreSQL features.
Load with `taop sandbox`.
