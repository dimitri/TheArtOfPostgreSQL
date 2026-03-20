# Sandbox

Test data and utilities for experimenting with PostgreSQL features.

## Files

### Schema
- `schema.sql` - Basic test schema
- `schema.tz.sql` - Schema with timezone support

### Data
- `lorem.sql` - Lorem ipsum text data
- `random.tz.sql` - Random data with timezone information
- `topn-with-comments.sql` - Top N query examples with comments

### Utilities
- `sandbox.indexes.sql` - Index examples and benchmarks
- `sandbox.sql` - Main entry point that loads all sandbox files

## Usage

```sql
\i sandbox/sandbox.sql
```

The sandbox provides test data for experimenting with SQL queries, indexes,
and PostgreSQL features in isolation.
