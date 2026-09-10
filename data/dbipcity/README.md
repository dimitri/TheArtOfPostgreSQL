# dbipcity

IP-to-city geolocation data, replacing the old MaxMind GeoLite2 dataset
(MaxMind's license changed and this repo no longer redistributes it).

## Data Source

[DB-IP City Lite](https://db-ip.com/db/download/ip-to-city-lite), September
2026 snapshot — licensed under
[CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).

**Attribution required by the license: IP Geolocation by DB-IP
(https://db-ip.com).**

## What's committed here

`dbipcity.csv.xz` is a filtered slice of the full ~7.75M-row global file,
not the original download:

- IPv4 only — `ip4r` (used for the containment/GiST queries in this chapter)
  doesn't cover IPv6 (it's a separate `ip6r` type in the same extension),
  and DB-IP's "IP to City Lite" file includes both.
- Great Britain (all of it — "GB" is the ISO code for the whole UK,
  England/Scotland/Wales/Northern Ireland, not just the island), France,
  and the whole US — GB/FR cover the book's ip4r worked examples (Roubaix
  FR, Oxford GB); the whole US (not just one state) also covers the
  hashtag/tweet chapter's US-wide geolocated data.

1,308,590 rows, **9.1 MB compressed** (79 MB decompressed) — committed as
`.xz`, not plain CSV: `xz -9e` beats `gzip -9` by a wide margin on this data
(9.1 MB vs 15 MB) and is available everywhere. Still committed directly
rather than via OVH Object Storage (see `datasets.md` for comparably-sized
committed datasets).

## Files

- `dbipcity.sql` — creates the `dbipcity` table and GiST index, `\copy`s
  `dbipcity.csv` in. Loaded with `taop dbipcity` (see
  `tooling/taop/dbipcity.lisp`), which decompresses `dbipcity.csv.xz` first
  — `xz-utils` is on the load path in both `docker/taop.Dockerfile` and
  `docker/seeded-postgres.Dockerfile`.
- `dbipcity.csv.xz` — `country,region,city,iprange,location` — `iprange`
  and `location` are already in `ip4r`/`point` text form (produced by a
  `COPY ... TO` from a throwaway load of the full dataset, not
  hand-transformed), so the load is a plain `\copy`, no pgloader.

## Regenerating from a newer DB-IP release

```bash
make                       # fetch + load + filter + stop-db, current month
make SNAPSHOT=2026-12      # a specific YYYY-MM release
```

Or step by step: `make fetch` downloads and unpacks the public CSV,
`make start-db` starts a throwaway Postgres container (the seeded image
already has `ip4r` installed), `make load` runs `load.sql` to `\copy` the
whole unfiltered file (~7.7M rows) into a staging table, `make filter` runs
`filter.sql` — one SQL statement builds the `dbipcity` table (IPv4 only,
GB/FR/whole US, `ip_start`/`ip_end` folded into `ip4r`), `\copy`s it back out
to `dbipcity.csv`, then `xz -9e`s it to `dbipcity.csv.xz` — and
`make stop-db`/`make clean` tear down.

No pgloader, and no text-munging of the CSV before it reaches Postgres: the
country/IPv4 filtering happens in `filter.sql` against already-loaded data,
not via `awk`/`cut` on the raw file (those aren't CSV-quote-aware and will
silently corrupt rows whose city name contains a comma, e.g. "Los Angeles
(Westwood, Los Angeles)").

After running it, bump the snapshot date in `dbipcity.sql`'s header comment
before committing.
