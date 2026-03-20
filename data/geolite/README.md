# GeoLite

MaxMind GeoLite2 geographic IP location data.

## Data Source

https://dev.maxmind.com/geoip/geoip2/geolite2/

## Note

Since 2019, MaxMind requires a license key to download GeoLite2 data.
The automated download has not been implemented in this repository.

## Manual Setup

1. Create a free account at https://www.maxmind.com/
2. Get your license key
3. Download GeoLite2-City-CSV.zip
4. Extract to this directory
5. Run with:
   ```bash
   pgloader geolite.load
   ```

Edit `geolite.load` to use the local zip file rather than the URL to fetch
it automatically, as it used to be possible.

## Files

- `geolite.sql` - Creates the `geolite` schema with location and blocks tables
- `geolite.load` - pgloader script for loading the CSV data
