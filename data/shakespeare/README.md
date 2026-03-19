# Shakespeare Data

Twitter-like dataset using Shakespeare play characters as users.

## Schema

Main entry point: `dream.sql`

This loads the complete schema and sample data in one transaction.

### Schema Files

- `tweets.norm.2.sql` - Core tweet schema (users, followers, lists, tweets)
- `tweets.activity.sql` - Materialized view of user activity counts
- `tweets.activity.nokey.sql` - Activity view without index

### Data Files

- `dream-theseus.sql` - Theseus user data
- `dream-users.sql` - Additional user data
- `dream-followers-love.sql` - Follower relationships
- `dream-followers-fairies.sql` - More follower relationships
- `dream-nickname-puck.sql` - Nickname data for Puck
- `dream-nicknames.sql` - General nickname mappings
- `dream-view-counters.sql` - View counter data
- `dream-mat-view.sql` - Materialized view

### Utility Files

- `counters.sql` - Counter utilities
- `tweets.hll.sql` - HyperLogLog statistics
- `tweets.uniques.sql` - Unique user counting
- `tweets.visitor.sql` - Visitor tracking
- `tweets.update.proc.sql` - Update procedures
- `tweets.norm.1.sql` - Normalization step 1
- `tweets.norm.full.sql` - Full normalization

### Triggers

- `dream-trigger-counter.sql` - Counter trigger
- `dream-trigger-daily.sql` - Daily tracking trigger
- `dream-trigger-hashtag.sql` - Hashtag tracking trigger

## Usage

```sql
\i data/shakespeare/dream.sql
```

This creates the `tweet` schema with users, followers, and tweets tables,
populated with Shakespeare play characters as users.
