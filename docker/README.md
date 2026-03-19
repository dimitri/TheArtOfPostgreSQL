# Docker

Docker images for The Art of PostgreSQL.

## Services

- **postgres** - PostgreSQL 16 database
- **taop** - The Art of PostgreSQL tool with SQL queries and cdstore app
- **psql** - PostgreSQL interactive client

## Usage

```bash
# Start all services
docker compose up -d

# Run the taop tool
docker compose run --rm taop

# Open psql prompt
docker compose run --rm psql

# Load Magic: The Gathering data
docker compose run --rm taop magic

# Load pubnames data
docker compose run --rm taop pubnames

# Load scan34 access logs
docker compose run --rm taop scan34 <output.csv>
```

## Building

```bash
docker compose build
```
