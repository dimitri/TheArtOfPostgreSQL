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

## Vendored assets

`frontend/dist/sqlfmt.wasm` and `frontend/dist/wasm_exec.js` back the
editor's FORMAT button and are embedded into the binary along with the HTML.
They come from [dimitri/sqlfmt](https://github.com/dimitri/sqlfmt)'s
`wasm-dev` release rather than being built here:

```bash
../../tooling/query-ui/update-sqlfmt-wasm.sh
```

That refreshes both files and stamps `frontend/dist/SQLFMT-VERSION.txt` with
the sqlfmt commit and a sha256. Rebuild the binary afterwards to pick them
up. `wasm_exec.js` must stay TinyGo's copy — the standard Go toolchain ships
a different file under the same name and the two are not interchangeable.

## Test

```bash
go test ./...
```
