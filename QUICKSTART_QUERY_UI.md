# Query UI — Quick Start

## Start it

```bash
docker compose up -d
```

First run pulls postgres pre-seeded from ghcr.io and builds query-ui locally
— no separate build step. Then open:

```
http://localhost:8042
```

See the [README Quick Start](README.md#quick-start) for building from source
instead of pulling.

## Two views

- **Book Queries** (`/`) — the full book table of contents in the sidebar.
  Pick a query, it loads into the editor; **Run** executes it, **EXPLAIN**
  shows the query plan (Text/Diagram/JSON tabs), **↓ CSV** downloads the
  results.
- **Starter Kit** (`/starter-kit.html`) — six guided labs as a runnable
  notebook. Each `sql` cell has its own **▶ Run** button and its own output,
  right next to the prose explaining it.

Query results that are geometry (GeoJSON, or a query that builds its own
`<svg>...</svg>` output) render as an inline map automatically — no setup
needed, just run the query.

## What's running

- **PostgreSQL**: `localhost:5433` (also reachable via the psql tool service —
  see [docker/docker-compose.tools.yml](docker/docker-compose.tools.yml))
- **Query UI**: `localhost:8042`

## Keeping it up to date

- Edited a `.sql`/`.md` file under `queries/` or `starter-kit/`, or
  `toc.txt`? → `docker compose restart query-ui`
- Edited anything under `src/query-ui/` (Go source or the embedded
  frontend)? → `docker compose build query-ui && docker compose up -d
  query-ui`

See the [README](README.md#query-ui--browse-and-run-queries-in-the-browser)
for why these two cases differ, and [QUERY_UI_GUIDE.md](QUERY_UI_GUIDE.md)
for the full reference (architecture, API endpoints, security model).

## Troubleshooting

**Port already in use?** Something else is bound to 5433 or 8042 — stop it,
or change the published port in `docker-compose.yml`.

**Database connection error on first start?** The seed restore runs on first
`docker compose up` and can take 10–30 seconds. The query-ui waits for
postgres's healthcheck (which uses TCP, not the unix socket, so it only
passes once the real server is ready). If it still fails:
```bash
docker compose logs postgres --tail 30
docker compose ps   # postgres should show "healthy"
```

**A query file or starter-kit page doesn't show up?** Check it's actually
listed in `toc.txt` (for book queries) or is an `NN-name.md` file directly
under `starter-kit/` — then restart (see above).
