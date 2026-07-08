# query-ui

The Go server behind the book's [Query UI](../../QUICKSTART_QUERY_UI.md) —
see [../../QUERY_UI_GUIDE.md](../../QUERY_UI_GUIDE.md) for the full
reference (features, architecture, API, security model). This file only
covers building and running the binary directly, outside Docker.

## Build & run

```bash
go mod download
go build -o query-ui
DATABASE_URL=postgresql://taop:taop@localhost:5433/taop ./query-ui
```

## Flags

```
-port         HTTP port (default: 8042)
-db           PostgreSQL connection URL (falls back to $DATABASE_URL, then
              postgresql://taop:taop@localhost:5433/taop)
-queries      Path to the queries directory (default: ../queries)
-toc          Path to toc.txt (default: ../toc.txt)
-params       Path to query-params.json (default: ../query-params.json)
-starter-kit  Path to the starter-kit directory (default: ../starter-kit)
-healthcheck  Probe /health on -port and exit 0/1 (used as the Docker
              HEALTHCHECK; the scratch image has no shell/wget)
```

## Test

```bash
go test ./...
```
