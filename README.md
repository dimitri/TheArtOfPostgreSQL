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

Use the taop service to load datasets. The main datasets are:

```bash
# Load Shakespeare tweet data (default play: dream.xml)
docker compose run --rm taop tweet

# Load Magic: The Gathering card data
docker compose run --rm taop magic

# Load currency exchange rates
docker compose run --rm taop rates

# Load scan34 access logs (default: SCAN34_DIR/access.csv)
docker compose run --rm taop scan34

# Load pubnames data (public houses from OpenStreetMap)
docker compose run --rm taop pubnames
```

### Query Data

Use the psql service for interactive querying with all SQL queries from the book:

```bash
docker compose run --rm psql
```

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

### Stop Services

```bash
docker compose down
```

