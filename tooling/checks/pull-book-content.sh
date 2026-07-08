#!/usr/bin/env bash
# Finds new or changed query files (.sql/.py/.java/.diff) in a book source
# checkout relative to this repo's queries/ directory, and stages them for
# review — it does NOT merge into queries/ automatically.
#
# Why staging, not auto-merge: a real diff against /Users/dim/dev/TAOP/
# taop-vol-1 found its queries are not a drop-in match for this lab —
# e.g. its version of the Chinook "alesi" query still used the old
# camelCase column names this lab's queries/ was fixed away from. Content
# pulled from the book source needs the same review this lab's existing
# queries already went through (run-all.sh, plus a read for \set/regresql-
# param issues) before landing in queries/.
set -euo pipefail
cd "$(dirname "$0")/../.."

SOURCE="${1:?Usage: $0 <path-to-book-source-checkout> [staging-dir]}"
STAGING="${2:-/tmp/book-pull-staging}"

if [ ! -d "$SOURCE" ]; then
  echo "Source directory not found: $SOURCE" >&2
  exit 1
fi

# Only en/ is canonical source. A first pass over the whole checkout found
# build/en and build/ua (rendered duplicates from the pandoc/LaTeX pipeline)
# and a top-level ua/ (a translated variant) — scanning those alongside en/
# both double-counts every file and, worse, lets basename matching below
# cross-match completely unrelated content that happens to share a
# generic name like "07_04.sql" in a different chapter.
EN_SOURCE="$SOURCE/en"
if [ ! -d "$EN_SOURCE" ]; then
  echo "Expected an en/ subdirectory under $SOURCE, found none — check the path." >&2
  exit 1
fi

rm -rf "$STAGING"
mkdir -p "$STAGING/new" "$STAGING/changed" "$STAGING/ambiguous"

echo "Scanning $EN_SOURCE for .sql/.py/.java/.diff files..."
echo

new_count=0
changed_count=0
ambiguous_count=0

while IFS= read -r -d '' src_file; do
  base=$(basename "$src_file")
  rel="${src_file#"$SOURCE"/}"

  # A basename that's purely digits/underscores ("07_04.sql", "12_01.sql")
  # repeats across unrelated chapters in both trees — matching on it alone
  # would compare two coincidentally-same-numbered but otherwise unrelated
  # queries and call the result "changed". Any real descriptive text in the
  # stem ("07_01_tweets.activity", "alesi", "fig-castles-paris") is specific
  # enough to safely cross-reference regardless of whether it also has a
  # numeric prefix; bare-numeric stems are staged separately for a human to
  # place by reading the surrounding chapter context.
  stem="${base%.*}"
  if [[ "$stem" =~ ^[0-9_]+$ ]]; then
    dest="$STAGING/ambiguous/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$src_file" "$dest"
    echo "  ambiguous (generic name, needs manual placement): $rel"
    ambiguous_count=$((ambiguous_count + 1))
    continue
  fi

  existing=$(find queries -name "$base" -not -path "*/regresql/*" | head -1)

  if [ -z "$existing" ]; then
    dest="$STAGING/new/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$src_file" "$dest"
    echo "  new:     $rel"
    new_count=$((new_count + 1))
  elif ! diff -q "$src_file" "$existing" > /dev/null 2>&1; then
    dest="$STAGING/changed/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$src_file" "$dest"
    echo "  changed: $existing  (source: $rel)"
    changed_count=$((changed_count + 1))
  fi
done < <(find "$EN_SOURCE" -type f \( -name "*.sql" -o -name "*.py" -o -name "*.java" -o -name "*.diff" \) -print0)

echo
echo "$new_count new file(s) staged in $STAGING/new/"
echo "$changed_count changed file(s) staged in $STAGING/changed/"
echo "$ambiguous_count generically-named file(s) staged in $STAGING/ambiguous/ (needs manual placement)"
echo
echo "Nothing in queries/ was touched. To bring content in:"
echo "  1. Run tooling/checks/run-all.sh against a copy with the staged"
echo "     file(s) added, to catch naming/\\set issues before they land."
echo "  2. Review each staged file — check table/column names against the"
echo "     actual loaded schema, and whether it needs its own \\set lines"
echo "     (a query relying on a sibling file's \\set in the book's"
echo "     continuous-session model will not work standalone here)."
echo "  3. Copy the reviewed file into the right place under queries/,"
echo "     and add a toc.txt entry if it's new content."
