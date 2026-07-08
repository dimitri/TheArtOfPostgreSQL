#!/usr/bin/env bash
# Fails if any query file references the pre-migration Chinook column names
# (albumid, artistid, ...) instead of the snake_case schema actually loaded
# (album_id, artist_id, ...). 27 files had exactly this bug before being
# fixed by hand; this is a regression gate so it doesn't come back via a
# book-content pull (see pull-book-content.sh) or a careless edit.
#
# These names are specific enough that a plain word-boundary match has no
# realistic false positives (unlike a generic :name-style scan — see
# check-set-dependencies.sh for why that one needs an allowlist).
set -euo pipefail
cd "$(dirname "$0")/../.."

PATTERN='\b(albumid|artistid|genreid|trackid|customerid|employeeid|invoiceid|invoicelineid|playlistid|mediatypeid|reportsto|supportrepid|billingaddress|billingcity|billingstate|billingcountry|billingpostalcode|unitprice)\b'

matches=$(grep -rlEi "$PATTERN" queries/ --include="*.sql" || true)

if [ -n "$matches" ]; then
  echo "FAIL: deprecated (pre-snake_case) Chinook column names found in:"
  echo "$matches" | sed 's/^/  /'
  echo
  echo "The loaded chinook schema uses snake_case (album_id, artist_id, ...)."
  echo "Fix: rename to snake_case, e.g. albumid -> album_id, trackid -> track_id."
  exit 1
fi

echo "OK: no deprecated Chinook column names found"
