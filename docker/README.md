# Docker

Docker images for The Art of PostgreSQL.

## Services

- **postgres** - PostgreSQL 16 database
- **taop** - The Art of PostgreSQL tool with SQL queries and cdstore app
- **commitlog** - taop with PostgreSQL and pgloader git repositories pre-fetched
- **psql** - PostgreSQL interactive client
- **geolite** - pgloader for loading GeoLite data

## Usage

```bash
# Build all images
docker compose build

# Start postgres
docker compose up -d postgres

# Run taop commands
docker compose run --rm taop

# Run commitlog commands (includes git repos)
docker compose run --rm commitlog

# Open psql prompt
docker compose run --rm psql

# Load data with taop
docker compose run --rm taop tweet
docker compose run --rm taop magic
docker compose run --rm taop rates
docker compose run --rm taop moma
docker compose run --rm taop opendata
docker compose run --rm taop eav

# Load commitlog data
docker compose run --rm commitlog commitlog
docker compose run --rm commitlog gitlog init
docker compose run --rm commitlog gitlog import postgres
docker compose run --rm commitlog gitlog import pgloader

# Load GeoLite data (requires manual download)
docker compose run --rm geolite
```

## Images

- **taop** - General purpose tool, smaller image (no git repos)
- **commitlog** - Includes PostgreSQL and pgloader git repositories (~2GB)

## Environment Variables

The following environment variables configure dataset locations in the
Docker container. See ../docker-compose.yml for setup:

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
