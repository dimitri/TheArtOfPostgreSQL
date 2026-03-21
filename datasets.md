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
