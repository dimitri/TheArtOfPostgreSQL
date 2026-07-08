#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo "Building query-ui..."
CGO_ENABLED=0 go build -o query-ui .

echo "✓ Built: $(pwd)/query-ui"
echo ""
echo "Usage:"
echo "  ./query-ui                   # Uses defaults"
echo "  ./query-ui -port 8080        # Custom port"
echo ""
echo "Environment:"
echo "  DATABASE_URL=... ./query-ui  # Override DB connection"
