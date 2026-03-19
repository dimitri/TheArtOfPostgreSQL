# Magic: The Gathering Dataset

Data from the Magic: The Gathering card game.

## Files

- `magic.sql` - Creates the `magic` schema with a `allsets` table containing JSONB data
- `magic.cards.sql` - Creates a `cards` table with flattened card data
- `MagicAllSets.json` - Source data containing all Magic sets
- `magic.py` - Python script to load and process the data

## Usage

```sql
\i magic.sql
\i magic.cards.sql
```
