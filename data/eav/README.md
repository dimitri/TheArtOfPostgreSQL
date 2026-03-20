# Entity-Attribute-Value (EAV)

Sample data demonstrating the Entity-Attribute-Value database design pattern.

## Files

- `eav.sql` - Main entry point that loads all EAV scripts
- `eav.create.params.sql` - Creates the EAV schema and parameter tables
- `eav.insert.params.sql` - Inserts sample parameter data
- `eav.support.sql` - Support functions and views for EAV queries

## Usage

```sql
\i eav/eav.sql
```

## About EAV

The Entity-Attribute-Value pattern is a database design pattern used to store
semi-structured or dynamically typed data where the traditional fixed schema
approach is too rigid. It allows adding new attributes without altering the
database schema.

## From The Art of PostgreSQL

In Chapter 30 of the book [The Art of
PostgreSQL](https://theartofpostgresql.com) titled **Modelization
Anti-Patterns** we read the following intro.

Failures to follow normalization forms opens the door to anomalies as seen
previ- ously. Some failure modes are so common in the wild that we can talk
about anti- patterns. One of the worst possible design choices would be the
EAV model.
