# Datasets

This repository includes several datasets for learning SQL with PostgreSQL:

## Shakespeare (tweet)

Twitter-like dataset using Shakespeare play characters as users. Contains
users, followers, lists, and tweets. Load with `taop tweet`.

## Magic: The Gathering (magic)

Complete card database from the Magic: The Gathering card game in JSON
format. Contains sets, cards, and card attributes. Load with `taop magic`.

## Currency Exchange Rates (rates)

IMF currency exchange rates data with daily rates for multiple currencies
over time. Includes typed tables with exclusion constraints. Load with `taop
rates`.

## Scan34 Access Logs (scan34)

Apache access log data from the scan34 web server. Contains IP addresses,
timestamps, requests, and HTTP status codes. Load with `taop scan34`.

## Pubnames

Public house names and locations from OpenStreetMap. Contains geographic
positions and names of pubs in the UK. Load with `taop pubnames`.

## Ergast F1 Database (f1db)

Formula 1 racing data from the Ergast Developer API. Contains races,
drivers, constructors, results, and seasons from 1950 to present. Load with
`taop f1db`.

## MoMA (moma)

Museum of Modern Art artist collection data. Contains artist names, biographies,
nationalities, and identifiers. Load with `taop moma`.

## Open Data (opendata)

Various open datasets including hello world translations, Archives de la Planète
photo collection, and CIA World Factbook data. Load with `taop opendata`.

## CD Store (cdstore)

Sample e-commerce application data with customers, products, orders, and
inventory.

## Git Log (commitlog)

Git commit logs from PostgreSQL and pgloader repositories. Fetch with:
```bash
taop gitlog fetch postgres
taop gitlog fetch pgloader
```
Then use `taop gitlog <csv> <project-directory>` to parse logs.

## GeoLite

MaxMind GeoLite2 geographic IP location data for geolocation queries.

## EAV (Entity-Attribute-Value)

Sample data demonstrating the Entity-Attribute-Value database design pattern with
various attributes. Load with `taop eav`.

## Sandbox

Various test data and utilities for experimenting with PostgreSQL features.
Load with `taop sandbox`.

## Counter

Synthetic dataset simulating a monotonic counter with reset events. Represents
typical resource consumption metrics used for invoicing (e.g., API calls, 
bandwidth usage, storage consumption).

**Schema:** `counter.measures(tick int, nb int)`
- `tick`: Time step identifier
- `nb`: Counter value at that step

**Use cases:**
- Window functions with running totals
- Computing deltas between steps
- Detecting and handling resets in metrics

**Load:** `docker compose run --rm taop counter`

## GeoNames

A 1% sample of the GeoNames geographical database with ~115,000 locations from
around the world. Includes administrative divisions, features, and spatial
indexing via GiST.

**Schema:** `geoname.*` (class, feature, country, region, district, geoname)
- `geoname.geoname`: locations with point geometry, country/region/district codes
- `geoname.country`: country/continent/region information
- `geoname.region`: state/province level administrative divisions
- `geoname.district`: county/district level administrative divisions
- `geoname.class` / `geoname.feature`: feature classification

**Load:** `docker compose run --rm taop geonames`

**Note:** This is a 1% sample (115k rows) for learning; the full GeoNames
database is 1.5 GB. Output row counts won't match the book (which used the
full database), but all queries work correctly on the sample.

## Last.fm

A collection of 10,262 tracks from the Last.fm music dataset with artist names,
track titles, and track IDs. Fully powers Chapter 8's trigrams section.

**Schema:** `lastfm.track(tid, artist, title)`

**Load:** `docker compose run --rm taop lastfm`

**Note:** This is a subset (12 MB) for learning. The full Last.fm database
including tag tables is ~1 GB (phase 2, optional).

To obtain the subset ZIP file:
```bash
curl -L -o lastfm_subset.zip http://labrosa.ee.columbia.edu/millionsong/sites/default/files/lastfm/lastfm_subset.zip
# Place in data/lastfm/ or set LASTFM_DIR env var
```

## Hashtag (Follow the Hashtag)

A collection of 200,000 geolocated tweets from the USA. Two tables:
- `public.tweet`: raw tweet data with user info and location (latitude/longitude)
- `public.hashtag`: hashtags extracted via regex with a GIN index on the
  `hashtags text[]` array

The CSV (≈90 MB) is fetched at Docker build time from OVH Cloud Object Storage
and is NOT committed to git.

**Load:** `docker compose run --rm taop hashtag`

**Source:** http://followthehashtag.com/datasets/free-twitter-dataset-usa-200000-free-usa-tweets/
