#!/usr/bin/env bash
#
# poststart.sh — run once on first Codespace start; skip on resume.
#
# Called by postStartCommand in devcontainer.json from workspaceFolder, so
# relative paths resolve inside the checked-out repository.
#
set -euo pipefail

# Stamp file lives in the persistent workspace.  When a Codespace is stopped
# and resumed, the postgres volume and the workspace directory both persist,
# so the stamp correctly skips re-loading an already-populated database.
STAMP="${GITHUB_WORKSPACE:-${PWD}}/.devcontainer/.loaded"

if [ -f "$STAMP" ]; then
  echo "==> Database already loaded (stamp file present). Skipping."
  echo "==> Connect with: psql"
  exit 0
fi

echo "==> Loading all datasets (~8 s)..."
taop load-data

echo "==> Loading commitlog git histories (repos are pre-cloned in image)..."
taop commitlog

echo "==> Configuring roles and search paths..."
psql -v ON_ERROR_STOP=1 \
  -c "ALTER ROLE taop SET search_path TO f1db, chinook, public, scan34;" \
  -c "CREATE USER cdstore WITH PASSWORD 'cdstore';" \
  -c "GRANT USAGE ON SCHEMA chinook TO cdstore;" \
  -c "ALTER ROLE cdstore SET search_path TO chinook;" \
  -c "GRANT SELECT ON ALL TABLES IN SCHEMA chinook TO cdstore;"

touch "$STAMP"
echo ""
echo "==> Done!  Connect with: psql"
echo "==> Run regression tests: cd queries && regresql test"
