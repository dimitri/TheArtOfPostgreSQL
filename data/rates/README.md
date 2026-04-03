# Exchange Rate Archives by Month

The data comes from:

  https://www.imf.org/external/np/fin/data/param_rms_mth.aspx

It is possible to download a TSV file from the website, but then you have to
manually process it. Here's what it looks like:

~~~
Currency units per SDR for May 2017
Currency	May 01, 2017	May 02, 2017	May 03, 2017	...
Chinese Yuan	NA	9.445190	9.439220	...
~~~

Each month is split into two files (part 1 and part 2), for 15 days each or thereabouts.

## Loading the Data

Use the `taop rates` command to load the data directly into PostgreSQL:

~~~bash
docker compose run --rm taop rates
~~~

This will:

1. Create the `raw.rates` table
2. Parse TSV files and COPY data directly to PostgreSQL (no intermediate CSV)
3. Create `public.rates` with `daterange` type and exclusion constraint
4. Create the typed `public.rate` table

## Schema

- `raw.rates`: Staging table with raw currency, date, rate data
- `public.rates`: Main table with `daterange` validity periods and exclusion constraint
- `public.rate`: Typed table of type `rate_t` with exclusion constraint
