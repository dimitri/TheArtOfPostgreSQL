# Museum of Modern Art (MoMA) Dataset

Artist data from the Museum of Modern Art collection.

## Files

### Schema
- `artists.sql` - Creates the `moma` schema with the `artist` table

### Data
- `artists/` - CSV files with artist data (different snapshots)
  - `artists.2017-05-01.csv`
  - `artists.2017-06-01.csv`
  - `artists.2017-07-01.csv`
  - `artists.2017-08-01.csv`
  - `artists.2017-09-01.csv`

### Updates
- `artists.update.sql` - Update artist data
- `artists.update.conflict.sql` - Update with conflict handling
- `artists.update.hstore.sql` - Update using hstore

### Audit (hstore)
- `hstore-audit-table.sql` - Creates audit table
- `hstore-audit-table-relname.sql` - Audit with relation name
- `hstore-audit-trigger.sql` - Trigger for hstore audit trail

## Usage

```sql
\i moma/artists.sql
```

Artist data includes: constituent ID, name, bio, nationality, gender, birth/death years, and Wikipedia/ULAN IDs.
