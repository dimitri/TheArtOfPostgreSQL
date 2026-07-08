#!/usr/bin/env bash
# Pre-merge gate: run every content-correctness check against queries/.
# Wired into CI (see .github/workflows/ci.yml) and safe to run locally
# before committing new or pulled query content.
set -euo pipefail
cd "$(dirname "$0")"

status=0
for check in check-*.sh; do
  echo "== $check =="
  if ! ./"$check"; then
    status=1
  fi
  echo
done

exit $status
