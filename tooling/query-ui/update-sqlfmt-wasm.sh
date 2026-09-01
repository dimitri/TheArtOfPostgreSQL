#!/usr/bin/env bash
# Vendor the sqlfmt WebAssembly build into src/query-ui/frontend/dist/.
#
# The FORMAT button in the query editor runs sqlfmt entirely in the browser:
# no /api/format endpoint, no round trip, and -- the point -- no network. The
# lab is meant to work from `docker compose up -d` onwards with nothing but
# the pulled images, so the .wasm and its glue are committed here and embedded
# into the query-ui binary by the //go:embed frontend/dist/* in main.go,
# rather than fetched from GitHub at page load.
#
# Both files come from dimitri/sqlfmt's wasm-dev release, which CI re-uploads
# on every green push to main (the tag's publish date stays at its creation,
# so read SQLFMT-VERSION.txt below, not the release date, to know what is
# vendored here). wasm_exec.js MUST be the copy from that release: it is
# TinyGo's glue, which is not interchangeable with the standard Go
# toolchain's file of the same name.
#
# Run this to pick up a new sqlfmt, then rebuild query-ui and commit the diff.
set -euo pipefail
cd "$(dirname "$0")/../.."

DEST="src/query-ui/frontend/dist"
REPO="dimitri/sqlfmt"
TAG="wasm-dev"

command -v gh >/dev/null || { echo "gh CLI is required" >&2; exit 1; }

echo "Fetching $REPO $TAG assets into $DEST/ ..."
gh release download "$TAG" --repo "$REPO" --clobber \
   --pattern sqlfmt.wasm --pattern wasm_exec.js --dir "$DEST"

# Stamp what we vendored. The release always carries a second, sha-named copy
# of the same bytes (sqlfmt-<short-sha>.wasm); that name is the only place the
# source commit is recorded, so recover it by matching sizes.
sha=$(gh release view "$TAG" --repo "$REPO" --json assets \
        --jq '.assets[].name | select(startswith("sqlfmt-") and endswith(".wasm"))' \
      | sed 's/^sqlfmt-//;s/\.wasm$//' | head -1)

{
  echo "sqlfmt WebAssembly build vendored into this directory."
  echo
  echo "source:   https://github.com/$REPO"
  echo "commit:   ${sha:-unknown}"
  echo "release:  $TAG"
  echo "vendored: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "sha256:   $(shasum -a 256 "$DEST/sqlfmt.wasm" | cut -d' ' -f1)"
  echo
  echo "Refresh with tooling/query-ui/update-sqlfmt-wasm.sh, then rebuild query-ui."
} > "$DEST/SQLFMT-VERSION.txt"

ls -lh "$DEST/sqlfmt.wasm" "$DEST/wasm_exec.js" | awk '{print "  " $9 "  " $5}'
echo
cat "$DEST/SQLFMT-VERSION.txt"
