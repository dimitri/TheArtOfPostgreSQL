-- Extensions the book's queries reference across various chapters (data
-- types, geolocation, text search), created once at database initialization
-- so SELECT queries using them (similarity(), cube(), earth_distance(),
-- hstore, intarray operators, uuid_generate_v4(), ip4r ranges) work
-- out of the box — without needing a CREATE EXTENSION statement to succeed
-- through query-ui's interactive editor first, which blocks it as a write
-- operation (see handleQueryExecute's read-only transaction guard).
--
-- earthdistance depends on cube, so cube must be created first.
create extension if not exists pg_trgm;
create extension if not exists cube;
create extension if not exists earthdistance;
create extension if not exists hstore;
create extension if not exists intarray;
create extension if not exists "uuid-ossp";
create extension if not exists ip4r;

-- NOT installed: plxslt (queries/05-data-types/24-non-relational-types/
-- 03_01.sql, an XSLT-via-SQL example). It has no PGDG package and no
-- actively maintained source release — building it would mean pinning to
-- an old/unmaintained fork. Left out; that one example query is expected to
-- fail with "extension \"plxslt\" is not available" until/unless someone
-- wants to take that on separately.
