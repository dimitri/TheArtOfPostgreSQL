#!/usr/bin/env bash
# Fails if a query file references a psql :name / :'name' / :"name" variable
# that isn't \set anywhere in that same file — the file is expected to be
# self-sufficient (see queries/02-intro/02-usecase/07_01.sql, which had
# exactly this bug: it used :'start' relying on \set start from a sibling
# file in a continuous psql session, which query-ui does not replicate).
#
# Two categories are deliberately not failures:
#
#  - Files with a regresql plan (queries/regresql/plans/.../<name>.yaml):
#    these are intentionally parameterized via regresql's own bind-value
#    mechanism to illustrate passing values from application code, not
#    forgotten \set lines. Make them runnable in query-ui via
#    query-params.json instead (see that file's _comment).
#
#  - ALLOWLIST below: reviewed false positives where a ":\"..." or ":'...'"
#    pattern is a JSON string literal or an XML namespace prefix, not a
#    variable reference. Re-review if these files' content changes.
#
# Implemented in Perl rather than `grep -P`: BSD grep (the macOS default)
# has no -P/lookbehind support at all and errors out silently under
# `set -euo pipefail` inside a command substitution, which previously made
# this check pass locally for the wrong reason (it never actually scanned
# anything). Perl ships with both macOS and the Ubuntu CI runner and
# handles the lookbehind identically on both.
set -euo pipefail
cd "$(dirname "$0")/../.."

perl -e '
use strict;
use warnings;

my @allowlist = (
  "queries/02-intro/03-postgresql/01_01.sql",
  "queries/06-data-modeling/33-not-only-sql/01_04.sql",
  "queries/05-data-types/24-non-relational-types/03_01.sql",
);
my %allowlisted = map { $_ => 1 } @allowlist;

my $fail = 0;

open(my $find, "-|", "find", "queries", "-name", "*.sql") or die $!;
while (my $file = <$find>) {
  chomp $file;
  next if $allowlisted{$file};

  (my $rel = $file) =~ s{^queries/}{};
  (my $plan = $rel) =~ s{\.sql$}{.yaml};
  next if -f "queries/regresql/plans/$plan";

  open(my $fh, "<", $file) or die "$file: $!";
  local $/;
  my $content = <$fh>;
  close $fh;

  # :name / :"name" / :'"'"'name'"'"' reference, excluding the :: cast operator.
  my %used;
  while ($content =~ /(?<!:):([\x27"]?)([a-zA-Z_][a-zA-Z0-9_]*)\1?/g) {
    $used{$2} = 1;
  }

  my %defined;
  while ($content =~ /^\\set\s+([a-zA-Z_][a-zA-Z0-9_]*)/mg) {
    $defined{$1} = 1;
  }

  my @missing = grep { !$defined{$_} } sort keys %used;
  if (@missing) {
    print "FAIL: $file references undefined variable(s): @missing\n";
    $fail = 1;
  }
}
close $find;

if ($fail) {
  print "\n";
  print "Fix: copy the needed \x27\\set name value\x27 line into the file (see\n";
  print "queries/02-intro/02-usecase/07_01.sql for the pattern), or if this\n";
  print "is deliberately showing application-code parameterization (like a\n";
  print "regresql bind param), add a queries/regresql/plans/ entry and/or a\n";
  print "query-params.json entry instead of \\set.\n";
  exit 1;
}

print "OK: no undefined psql \\set dependencies found\n";
'
